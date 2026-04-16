import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_profile.dart';

class OfflineAudioService {
  OfflineAudioService(this._dio);
  final Dio _dio;
  static bool _migrationChecked = false;

  /// Resolves relative paths (e.g. /audio/...) against [Dio.options.baseUrl] so downloads work with VPS proxy.
  String _absoluteUrl(String url) {
    final t = url.trim();
    if (t.isEmpty) return t;
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    var base = _dio.options.baseUrl.trim();
    if (base.isEmpty) return t;
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      base = 'https://$base';
    }
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final path = t.startsWith('/') ? t : '/$t';
    return '$base$path';
  }

  static String _stableFileName(String remoteUrl) {
    final digest = md5.convert(utf8.encode(remoteUrl));
    return digest.toString();
  }

  /// Get persistent documents directory - survives app updates
  Future<Directory> _getAudioDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/hidaya_audio');
  }

  Future<File> _newCacheFile(String remoteUrl) async {
    final dir = await _getAudioDir();
    final name = _stableFileName(remoteUrl);
    return File('${dir.path}/$name.mp3');
  }

  Future<File> _legacyCacheFile(String remoteUrl, AudioProfile profile) async {
    final dir = await getApplicationSupportDirectory();
    final fileName = '${remoteUrl.hashCode.abs()}.mp3';
    return File('${dir.path}/audio/${profile.value}/$fileName');
  }

  /// Migrate files from old locations to new persistent location
  Future<void> _migrateIfNeeded() async {
    if (_migrationChecked) return;
    _migrationChecked = true;

    try {
      final newDir = await _getAudioDir();
      await newDir.create(recursive: true);

      // Check old ApplicationSupport directory
      final supportDir = await getApplicationSupportDirectory();
      final oldCacheDir = Directory('${supportDir.path}/audio/cache');

      // Migrate from cache subdirectory
      if (await oldCacheDir.exists()) {
        await for (final file in oldCacheDir.list()) {
          if (file is File && file.path.endsWith('.mp3')) {
            final fileName = file.path.split('/').last;
            final newPath = '${newDir.path}/$fileName';
            if (!await File(newPath).exists()) {
              await file.copy(newPath);
            }
          }
        }
      }

      // Migrate from profile subdirectories
      for (final p in AudioProfile.values) {
        final oldDir = Directory('${supportDir.path}/audio/${p.value}');
        if (await oldDir.exists()) {
          await for (final file in oldDir.list()) {
            if (file is File && file.path.endsWith('.mp3')) {
              final fileName = file.path.split('/').last;
              final newPath = '${newDir.path}/$fileName';
              if (!await File(newPath).exists()) {
                await file.copy(newPath);
              }
            }
          }
        }
      }
    } catch (_) {
      // Migration failure shouldn't block usage
    }
  }

  /// Resolves a cached file: new stable path first, then legacy per-profile folders.
  Future<File?> getCachedFile(String remoteUrl, AudioProfile profile) async {
    await _migrateIfNeeded();

    final resolved = _absoluteUrl(remoteUrl);
    final key = resolved.isNotEmpty ? resolved : remoteUrl;

    final primary = await _newCacheFile(key);
    if (await primary.exists()) {
      // Validate file before returning
      if (await _isValidAudioFile(primary)) {
        return primary;
      }
      // Invalid file, delete it
      try {
        await primary.delete();
      } catch (_) {}
    }
    
    // Legacy paths used raw [remoteUrl] hash; try both old and resolved keys.
    final legacyKeys = <String>{remoteUrl.trim(), key};
    for (final p in AudioProfile.values) {
      for (final lk in legacyKeys) {
        if (lk.isEmpty) continue;
        final leg = await _legacyCacheFile(lk, p);
        if (await leg.exists()) {
          if (!await _isValidAudioFile(leg)) {
            try {
              await leg.delete();
            } catch (_) {}
            continue;
          }
          try {
            await leg.copy(primary.path);
            return primary;
          } catch (_) {
            return leg;
          }
        }
      }
    }
    return null;
  }

  /// Check if file is valid (non-empty and has MP3 header)
  Future<bool> _isValidAudioFile(File file) async {
    try {
      if (!await file.exists()) return false;
      final size = await file.length();
      if (size == 0) return false;
      if (size < 1024) return false; // Minimum 1KB for valid audio
      
      // Check MP3 header (ID3 or MPEG sync)
      final header = await file.openRead(0, 4).expand((b) => b).toList();
      if (header.length >= 3) {
        // ID3 tag or MPEG sync word
        final isID3 = header[0] == 0x49 && header[1] == 0x44 && header[2] == 0x33;
        final isMPEG = header[0] == 0xFF && (header[1] & 0xE0) == 0xE0;
        return isID3 || isMPEG;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<File?> ensureCached(String remoteUrl, AudioProfile profile, {int retryCount = 3}) async {
    await _migrateIfNeeded();

    final resolved = _absoluteUrl(remoteUrl);
    final key = resolved.isNotEmpty ? resolved : remoteUrl.trim();

    final existing = await getCachedFile(remoteUrl, profile);
    if (existing != null) {
      // Validate existing file
      if (await _isValidAudioFile(existing)) {
        return existing;
      }
      // Invalid file, delete and re-download
      try {
        await existing.delete();
      } catch (_) {}
    }
    
    if (key.isEmpty) return null;

    final file = await _newCacheFile(key);
    final tempFile = File('${file.path}.tmp');

    for (var attempt = 0; attempt < retryCount; attempt++) {
      try {
        await file.parent.create(recursive: true);
        
        // Download to temp file first
        await _dio.download(
          key,
          tempFile.path,
          options: Options(
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 10),
          ),
        );
        
        // Validate downloaded file
        if (!await _isValidAudioFile(tempFile)) {
          throw Exception('Invalid audio file downloaded');
        }
        
        // Move temp to final location
        await tempFile.rename(file.path);
        
        return file;
      } catch (e) {
        // Clean up temp file
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {}
        
        // Last attempt failed
        if (attempt == retryCount - 1) {
          return null;
        }
        
        // Wait before retry
        await Future.delayed(Duration(seconds: 1 * (attempt + 1)));
      }
    }
    return null;
  }

  Future<void> deleteCachedFiles(List<String> remoteUrls) async {
    await _migrateIfNeeded();
    
    for (final url in remoteUrls) {
      if (url.isEmpty) continue;
      try {
        final primary = await _newCacheFile(url);
        if (await primary.exists()) await primary.delete();
      } catch (_) {}
      // Also delete from legacy locations
      for (final p in AudioProfile.values) {
        try {
          final leg = await _legacyCacheFile(url, p);
          if (await leg.exists()) await leg.delete();
        } catch (_) {}
      }
    }
  }
}
