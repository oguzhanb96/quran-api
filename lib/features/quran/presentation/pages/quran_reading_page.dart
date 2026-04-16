import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/audio/audio_profile.dart';
import '../../../../core/audio/offline_audio_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/network/app_dio.dart';
import '../../../../core/quran/tajweed_engine.dart';
import '../../../../core/settings/app_preferences.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../data/surah_data.dart';
import '../../domain/entities/surah_meta.dart';

/// Bumps when ayah–translation pairing logic changes (invalidates Hive cache).
const _quranSurahCacheVersion = '_pair_v1';

Map<int, String> _translationsByAyahNumber(List<dynamic> translationAyahs) {
  final out = <int, String>{};
  for (final raw in translationAyahs) {
    if (raw is! Map) continue;
    final m = Map<String, dynamic>.from(raw);
    final n = (m['numberInSurah'] as num?)?.toInt();
    final text = m['text'] as String?;
    if (n != null && n > 0 && text != null && text.isNotEmpty) {
      out[n] = text;
    }
  }
  return out;
}

class QuranReadingPage extends ConsumerStatefulWidget {
  const QuranReadingPage({super.key, required this.surahMeta});

  final SurahMeta surahMeta;

  @override
  ConsumerState<QuranReadingPage> createState() => _QuranReadingPageState();
}

class _AyahBundle {
  const _AyahBundle({
    required this.trackId,
    required this.numberInSurah,
    required this.arabicText,
    required this.translatedText,
    required this.primaryAudioUrl,
    required this.fallbackAudioUrl,
  });
  final String trackId;
  final int numberInSurah;
  final String arabicText;
  final String translatedText;
  final String primaryAudioUrl;
  final String fallbackAudioUrl;
}

class _AudioUiState {
  const _AudioUiState({required this.currentAudioUrl, required this.isPlaying});
  final String? currentAudioUrl;
  final bool isPlaying;
}

class _PlaybackState {
  const _PlaybackState({
    required this.currentAudioUrl,
    required this.position,
    required this.duration,
  });

  final String? currentAudioUrl;
  final Duration position;
  final Duration duration;
}

class _QuranReadingPageState extends ConsumerState<QuranReadingPage> {
  Dio? _dio;
  OfflineAudioService? _offlineAudioService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  bool _isLoading = true;
  String? _error;
  List<_AyahBundle> _ayahs = const [];

  late String _selectedLanguage;
  AudioProfile _selectedProfile = AudioProfile.male;
  String _selectedReciter = 'ar.alafasy';
  bool _tajweedEnabled = true;
  bool _showLegend = false;
  bool _isSaved = false;
  bool _isDownloaded = false;

  final ValueNotifier<_AudioUiState> _audioUiState = ValueNotifier(
    const _AudioUiState(currentAudioUrl: null, isPlaying: false),
  );
  final ValueNotifier<_PlaybackState> _playbackState = ValueNotifier(
    const _PlaybackState(
      currentAudioUrl: null,
      position: Duration.zero,
      duration: Duration.zero,
    ),
  );

  Timer? _readingTimer;
  Map<int, String> _externalAudioByAyah = <int, String>{};

  @override
  void initState() {
    super.initState();
    _selectedLanguage = AppPreferences.getQuranTranslationLang() ?? 'Türkçe';
  }

  static const _languageToEdition = <String, String>{
    'Türkçe': 'tr.diyanet',
    'English': 'en.asad',
    'Français': 'fr.hamidullah',
    'العربية': 'ar.muyassar',
    'اردو': 'ur.jalandhry',
    'Bahasa Indonesia': 'id.indonesian',
    'Deutsch': 'de.aburida',
  };

  static const _reciterByProfile = <AudioProfile, String>{
    AudioProfile.female: 'ar.hanirifai',
    AudioProfile.male: 'ar.alafasy',
  };

  static const _premiumReciters = <String, String>{
    'ar.alafasy': 'Mishary Alafasy',
    'ar.abdurrahmaansudais': 'Abdurrahman Sudais',
    'ar.husary': 'Mahmoud Al-Husary',
    'ar.mahermuaiqly': 'Maher Al Muaiqly',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dio == null) {
      _dio = ref.read(dioProvider);
      _offlineAudioService = OfflineAudioService(_dio!);
      _isSaved = AppPreferences.getSavedSurahs().contains(widget.surahMeta.number);
      _isDownloaded = AppPreferences.getDownloadedSurahs().contains(widget.surahMeta.number);
      _loadSurah();

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          final completedId = _audioUiState.value.currentAudioUrl;
          _audioUiState.value = _AudioUiState(
            currentAudioUrl: completedId,
            isPlaying: false,
          );
          _playbackState.value = _PlaybackState(
            currentAudioUrl: completedId,
            position: Duration.zero,
            duration: _playbackState.value.duration,
          );
          Future.microtask(() {
            _playNextAfterCurrent(completedId);
          });
        }
      });
      _tts.setCompletionHandler(() {
        final completedId = _audioUiState.value.currentAudioUrl;
        _audioUiState.value = _AudioUiState(
          currentAudioUrl: completedId,
          isPlaying: false,
        );
        Future.microtask(() {
          _playNextAfterCurrent(completedId);
        });
      });
      _tts.setProgressHandler((text, startOffset, endOffset, word) {
        final cur = _audioUiState.value.currentAudioUrl;
        if (cur != null && text.isNotEmpty) {
           final ratio = (endOffset / text.length).clamp(0.0, 1.0);
           final dur = const Duration(milliseconds: 10000);
           final pos = Duration(milliseconds: (10000 * ratio).toInt());
           _playbackState.value = _PlaybackState(
              currentAudioUrl: cur,
              position: pos,
              duration: dur,
           );
        }
      });
      _audioPlayer.positionStream.listen((position) {
        final cur = _audioUiState.value.currentAudioUrl;
        _playbackState.value = _PlaybackState(
          currentAudioUrl: cur,
          position: position,
          duration: _playbackState.value.duration,
        );
      });
      _audioPlayer.durationStream.listen((duration) {
        final cur = _audioUiState.value.currentAudioUrl;
        _playbackState.value = _PlaybackState(
          currentAudioUrl: cur,
          position: _playbackState.value.position,
          duration: duration ?? Duration.zero,
        );
      });

      _readingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        AppPreferences.incrementReadingProgress();
        AppPreferences.incrementTotalAppMinutes();
        AppPreferences.recordDailyReading(1.0);
      });
    }
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
    _tts.stop();
    _audioUiState.dispose();
    _playbackState.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSurah() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _audioPlayer.pause();
    } catch (_) {}
    _audioUiState.value = const _AudioUiState(
      currentAudioUrl: null,
      isPlaying: false,
    );

    try {
      final translationEdition =
          _languageToEdition[_selectedLanguage] ?? 'en.asad';
      final translationLang = translationEdition.split('.').first;
      final reciterEdition = _selectedProfile == AudioProfile.female
          ? (_reciterByProfile[AudioProfile.female] ?? 'ar.hanirifai')
          : _selectedReciter;
      final dio = _dio;
      if (dio == null) return;

      final surahId = widget.surahMeta.number;
      print('Loading surah $surahId from ${dio.options.baseUrl}');
      final backendAudioBase =
          '${dio.options.baseUrl}/audio/$reciterEdition/$surahId';
      _externalAudioByAyah = await _loadExternalAudioByAyah(
        surahId: surahId,
        reciterEdition: reciterEdition,
      );
      // Offline: if external audio couldn't be fetched, use cached download URLs
      if (_externalAudioByAyah.isEmpty) {
        final cachedUrls = AppPreferences.getSurahAudioUrls(surahId);
        if (cachedUrls.isNotEmpty) {
          for (var i = 0; i < cachedUrls.length; i++) {
            _externalAudioByAyah[i + 1] = cachedUrls[i];
          }
        }
      }

      final cacheKey =
          'surah_${surahId}_${translationEdition}_$reciterEdition$_quranSurahCacheVersion';
      final box = Hive.box('quran_cache');

      List<dynamic> arabicAyahs = [];
      List<dynamic> translationAyahs = [];

      final cachedResultStr = box.get(cacheKey);
      if (cachedResultStr != null && cachedResultStr is String) {
        final decoded = jsonDecode(cachedResultStr) as Map<String, dynamic>;
        arabicAyahs = decoded['arabic'] as List<dynamic>? ?? [];
        translationAyahs = decoded['translation'] as List<dynamic>? ?? [];
      } else {
        final results = await Future.wait<dynamic>([
          dio.get<Map<String, dynamic>>('/surah/$surahId'),
          dio.get<Map<String, dynamic>>(
            '/surah/$surahId/translations',
            queryParameters: {'lang': translationLang},
          ),
        ]);

        final surahData = results[0].data as Map<String, dynamic>?;
        final translationsData = results[1].data as Map<String, dynamic>?;
        final editions =
            (translationsData?['editions'] as List<dynamic>? ?? []);

        arabicAyahs = (surahData?['ayahs'] as List<dynamic>? ?? []);
        final editionListResponse = await dio.get<Map<String, dynamic>>('/editions');
        final editionList = (editionListResponse.data as List<dynamic>? ?? []);
        print('Editions count: ${editionList.length}');
        Map<String, dynamic>? selectedTranslation;
        for (final edition in editions.whereType<Map>()) {
          final editionMap = edition.cast<String, dynamic>();
          final meta = (editionMap['edition'] as Map?)?.cast<String, dynamic>();
          if (meta?['identifier'] == translationEdition) {
            selectedTranslation = editionMap;
            break;
          }
        }
        selectedTranslation ??= editions
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .firstWhere(
              (editionMap) =>
                  ((editionMap['edition'] as Map?)?['type']?.toString() ==
                      'translation') &&
                  ((editionMap['edition'] as Map?)?['language']?.toString() ==
                      translationLang),
              orElse: () => <String, dynamic>{},
            );
        translationAyahs =
            (selectedTranslation['ayahs'] as List<dynamic>? ?? []);

        final cacheData = {
          'arabic': arabicAyahs,
          'translation': translationAyahs,
        };
        await box.put(cacheKey, jsonEncode(cacheData));
      }

      final trByNum = _translationsByAyahNumber(translationAyahs);
      final bundles = <_AyahBundle>[];
      for (var i = 0; i < arabicAyahs.length; i++) {
        final ar = arabicAyahs[i] as Map<String, dynamic>;
        final numberInSurah = (ar['numberInSurah'] as int?) ?? i + 1;
        final backendFromField =
            (ar['audio'] as String?) ??
            ((ar['audioData'] as Map?)?['url'] as String?) ??
            (ar['audio_url'] as String?);
        bundles.add(
          _AyahBundle(
            trackId: '${widget.surahMeta.number}-$numberInSurah',
            numberInSurah: numberInSurah,
            arabicText: (ar['text'] as String?) ?? '',
            translatedText: trByNum[numberInSurah] ?? '',
            primaryAudioUrl:
                backendFromField ?? '$backendAudioBase/$numberInSurah.mp3',
            fallbackAudioUrl: _externalAudioByAyah[numberInSurah] ?? '',
          ),
        );
      }

      if (mounted) {
        setState(() {
          _ayahs = bundles;
          _isLoading = false;
        });
        AppPreferences.setLastRead(
          widget.surahMeta.number,
          widget.surahMeta.englishName,
          1,
        );
        AppPreferences.incrementTotalSurahsRead();
      }
    } catch (e) {
      print('Quran API Error: $e');
      print('Dio baseUrl: ${_dio?.options.baseUrl}');
      if (mounted) {
        final translationEdition =
            _languageToEdition[_selectedLanguage] ?? 'en.asad';
        final reciterEdition =
            _reciterByProfile[_selectedProfile] ?? 'ar.alafasy';
        final cacheKey =
            'surah_${widget.surahMeta.number}_${translationEdition}_$reciterEdition$_quranSurahCacheVersion';
        final box = Hive.box('quran_cache');
        final cachedResultStr = box.get(cacheKey);

        if (cachedResultStr != null && cachedResultStr is String) {
          final decoded = jsonDecode(cachedResultStr) as Map<String, dynamic>;
          final arabicAyahs = decoded['arabic'] as List<dynamic>? ?? [];
          final translationAyahs =
              decoded['translation'] as List<dynamic>? ?? [];

          final bundles = <_AyahBundle>[];
          final dio = _dio;
          final backendAudioBase =
              '${dio?.options.baseUrl ?? ''}/audio/$reciterEdition/${widget.surahMeta.number}';
          _externalAudioByAyah = await _loadExternalAudioByAyah(
            surahId: widget.surahMeta.number,
            reciterEdition: reciterEdition,
          );
          if (_externalAudioByAyah.isEmpty) {
            final cachedUrls = AppPreferences.getSurahAudioUrls(widget.surahMeta.number);
            for (var i = 0; i < cachedUrls.length; i++) {
              _externalAudioByAyah[i + 1] = cachedUrls[i];
            }
          }
          final trByNum = _translationsByAyahNumber(translationAyahs);
          for (var i = 0; i < arabicAyahs.length; i++) {
            final ar = arabicAyahs[i] as Map<String, dynamic>;
            final numberInSurah = (ar['numberInSurah'] as int?) ?? i + 1;
            final backendFromField =
                (ar['audio'] as String?) ??
                ((ar['audioData'] as Map?)?['url'] as String?) ??
                (ar['audio_url'] as String?);
            bundles.add(
              _AyahBundle(
                trackId: '${widget.surahMeta.number}-$numberInSurah',
                numberInSurah: numberInSurah,
                arabicText: (ar['text'] as String?) ?? '',
                translatedText: trByNum[numberInSurah] ?? '',
                primaryAudioUrl:
                    backendFromField ?? '$backendAudioBase/$numberInSurah.mp3',
                fallbackAudioUrl: _externalAudioByAyah[numberInSurah] ?? '',
              ),
            );
          }
          setState(() {
            _ayahs = bundles;
            _isLoading = false;
          });
          // Check for autoplay query param and start playing if present
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted || _ayahs.isEmpty) return;
            final routerState = GoRouterState.of(context);
            final autoplay = routerState.uri.queryParameters['autoplay'];
            if (autoplay == 'true') {
              _playTrack(_ayahs.first);
            }
          });
          return;
        }

        setState(() {
          _isLoading = false;
          _error = 'Sure yüklenemedi. İnternet bağlantınızı kontrol edin.';
        });
      }
    }
  }

  void _playNextAfterCurrent(String? completedTrackId) {
    if (completedTrackId == null || _ayahs.isEmpty) return;
    final idx = _ayahs.indexWhere((a) => a.trackId == completedTrackId);
    if (idx >= 0 && idx < _ayahs.length - 1) {
      // Bir miktar gecikme ekleyerek JustAudio state'inin çakışmasını engelle
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _playTrack(_ayahs[idx + 1]);
      });
    } else if (idx == _ayahs.length - 1) {
      // Son ayet tamamlandı, bir sonraki sureye geç
      final currentSurahNum = widget.surahMeta.number;
      if (currentSurahNum < 114) {
        final nextSurah = StaticSurahData.surahList[currentSurahNum]; // 0-indexed, so currentSurahNum is next index
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          // Navigate to next surah with auto-play flag
          context.pushReplacement('/quran/surah/${nextSurah.number}?autoplay=true');
        });
      }
    }
  }

  Future<void> _deleteCurrentSurahOfflineAudio() async {
    final service = _offlineAudioService;
    final savedUrls = AppPreferences.getSurahAudioUrls(widget.surahMeta.number);
    if (service != null) {
      await service.deleteCachedFiles(savedUrls);
    }
    await AppPreferences.clearSurahAudioUrls(widget.surahMeta.number);
    await AppPreferences.removeDownloadedSurah(widget.surahMeta.number);
    if (mounted) {
      setState(() => _isDownloaded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Offline ses silindi.',
            style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadCurrentSurahForOffline() async {
    if (!AppPreferences.isPremiumEnabled()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline ses indirme Premium gerektirir.'),
        ),
      );
      return;
    }
    final service = _offlineAudioService;
    if (service == null) return;

    final urlsToSave = <String>[];
    final failedAyahs = <int>[];
    var successCount = 0;

    // Show progress dialog or indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_ayahs.length} ayet indiriliyor...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    for (var i = 0; i < _ayahs.length; i++) {
      final ayah = _ayahs[i];
      final url = ayah.fallbackAudioUrl.isNotEmpty
          ? ayah.fallbackAudioUrl
          : ayah.primaryAudioUrl;
      if (url.isEmpty) {
        urlsToSave.add('');
        continue;
      }
      try {
        final cached = await service.ensureCached(url, _selectedProfile);
        if (cached == null) {
          failedAyahs.add(ayah.numberInSurah);
          urlsToSave.add(''); // Mark as failed
        } else {
          successCount++;
          urlsToSave.add(url);
        }
      } catch (_) {
        failedAyahs.add(ayah.numberInSurah);
        urlsToSave.add(''); // Mark as failed
      }
    }

    // Only save if all downloads succeeded
    if (failedAyahs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$successCount/${_ayahs.length} ayet indirildi. '
            'Ayet ${failedAyahs.join(", ")} indirilemedi. '
            'Tekrar deneyin.',
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // All succeeded - save and mark as downloaded
    await AppPreferences.saveSurahAudioUrls(
      widget.surahMeta.number,
      urlsToSave,
    );
    await AppPreferences.addDownloadedSurah(widget.surahMeta.number);

    if (!mounted) return;
    setState(() => _isDownloaded = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Tüm ${_ayahs.length} ayet başarıyla indirildi'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<Map<int, String>> _loadExternalAudioByAyah({
    required int surahId,
    required String reciterEdition,
  }) async {
    final dio = _dio;
    if (dio == null) {
      return <int, String>{};
    }
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '${AppConfig.quranApiBase}/surah/$surahId/$reciterEdition',
      );
      final ayahs = (response.data?['data']?['ayahs'] as List<dynamic>? ?? []);
      final mapped = <int, String>{};
      for (final ayah in ayahs.whereType<Map>()) {
        final map = ayah.cast<String, dynamic>();
        final numberInSurah = (map['numberInSurah'] as num?)?.toInt();
        final url = map['audio']?.toString();
        if (numberInSurah != null && url != null && url.isNotEmpty) {
          mapped[numberInSurah] = url;
        }
      }
      return mapped;
    } catch (_) {
      return <int, String>{};
    }
  }

  Future<void> _playTrack(_AyahBundle track) async {
    try {
      final ui = _audioUiState.value;
      final isSameTrack = ui.currentAudioUrl == track.trackId;

      if (isSameTrack && ui.isPlaying) {
        await _tts.stop();
        await _audioPlayer.pause();
        _audioUiState.value = _AudioUiState(
          currentAudioUrl: track.trackId,
          isPlaying: false,
        );
        return;
      }
      if (isSameTrack && !ui.isPlaying) {
        await _audioPlayer.play();
        _audioUiState.value = _AudioUiState(
          currentAudioUrl: track.trackId,
          isPlaying: true,
        );
        AppPreferences.setLastRead(
          widget.surahMeta.number,
          widget.surahMeta.englishName,
          track.numberInSurah,
        );
        return;
      }

      await _tts.stop();
      await _audioPlayer.stop();
      _audioUiState.value = _AudioUiState(
        currentAudioUrl: track.trackId,
        isPlaying: false,
      );
      _playbackState.value = const _PlaybackState(
        currentAudioUrl: null,
        position: Duration.zero,
        duration: Duration.zero,
      );
      final savedPerAyah = AppPreferences.getSurahAudioUrls(widget.surahMeta.number);
      final savedUrl = (track.numberInSurah - 1 >= 0 && track.numberInSurah - 1 < savedPerAyah.length)
          ? savedPerAyah[track.numberInSurah - 1]
          : '';
      final candidates = <String>[
        track.fallbackAudioUrl,
        savedUrl,
        track.primaryAudioUrl,
      ].where((url) => url.isNotEmpty).toSet().toList();
      var played = false;
      if (_selectedProfile == AudioProfile.male) {
        for (final url in candidates) {
          try {
            final offline = _offlineAudioService == null
                ? null
                : await _offlineAudioService!.getCachedFile(
                    url,
                    _selectedProfile,
                  );
            if (offline != null) {
              await _audioPlayer.setFilePath(offline.path);
            } else {
              await _audioPlayer.setUrl(url);
            }
            played = true;
            break;
          } catch (_) {}
        }
      }

      if (!played &&
          _selectedProfile == AudioProfile.female &&
          track.arabicText.trim().isNotEmpty) {
        await _tts.setLanguage('ar');
        await _tts.setSpeechRate(0.42);
        await _tts.setPitch(1.2);
        await _tts.speak(track.arabicText);
        _audioUiState.value = _AudioUiState(
          currentAudioUrl: track.trackId,
          isPlaying: true,
        );
        _playbackState.value = _PlaybackState(
          currentAudioUrl: track.trackId,
          position: Duration.zero,
          duration: const Duration(milliseconds: 10000),
        );
        AppPreferences.setLastRead(
          widget.surahMeta.number,
          widget.surahMeta.englishName,
          track.numberInSurah,
        );
        return;
      }
      if (!played) throw Exception('audio-unavailable');
      
      _audioUiState.value = _AudioUiState(
        currentAudioUrl: track.trackId,
        isPlaying: true,
      );
      _playbackState.value = _PlaybackState(
        currentAudioUrl: track.trackId,
        position: Duration.zero,
        duration: _playbackState.value.duration,
      );
      AppPreferences.setLastRead(
        widget.surahMeta.number,
        widget.surahMeta.englishName,
        track.numberInSurah,
      );
      
      await _audioPlayer.play();
    } catch (_) {
      // Playback failed. Automatically attempt next track to resume flow
      _audioUiState.value = const _AudioUiState(
        currentAudioUrl: null,
        isPlaying: false,
      );
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _playNextAfterCurrent(track.trackId);
        });
      }
    }
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        const navBarHeight = 106.0;
        final safeBottom = MediaQuery.of(ctx).padding.bottom;
        final bottomPad = navBarHeight + safeBottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppText.of(context, 'readingSettings'),
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: 'Çeviri Dili',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: _languageToEdition.keys
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLanguage = val);
                    AppPreferences.setQuranTranslationLang(val);
                    Navigator.pop(ctx);
                    _loadSurah();
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedProfile.value,
                decoration: InputDecoration(
                  labelText: 'Ses Profili',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'female',
                    enabled: AppPreferences.isPremiumEnabled(),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Kadın Sesi'),
                              Text(
                                'Sadece internet bağlantısı ile',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!AppPreferences.isPremiumEnabled()) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded, size: 10, color: Color(0xFF7C3AED)),
                                SizedBox(width: 3),
                                Text(
                                  'Premium',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const DropdownMenuItem(value: 'male', child: Text('Erkek Sesi')),
                ],
                onChanged: (val) {
                  if (val == null) return;
                  if (val == 'female' && !AppPreferences.isPremiumEnabled()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Kadın sesi Premium ile açılır.',
                          style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
                        ),
                        backgroundColor: const Color(0xFF7C3AED),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                    return;
                  }
                  setState(() => _selectedProfile = AudioProfile.fromValue(val));
                  Navigator.pop(ctx);
                  _loadSurah();
                },
              ),
              const SizedBox(height: 16),
              if (_selectedProfile == AudioProfile.male) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedReciter,
                  decoration: InputDecoration(
                    labelText: 'Kari Sesi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: _premiumReciters.entries.map((e) {
                    final isPremium = AppPreferences.isPremiumEnabled();
                    final isFree = e.key == 'ar.alafasy';
                    final isLocked = !isPremium && !isFree;
                    return DropdownMenuItem(
                      value: e.key,
                      enabled: !isLocked,
                      child: Row(
                        children: [
                          Expanded(child: Text(e.value, style: const TextStyle(fontFamily: 'Plus Jakarta Sans'))),
                          if (isLocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_rounded, size: 10, color: Color(0xFF7C3AED)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    if (!AppPreferences.isPremiumEnabled() && val != 'ar.alafasy') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Tüm kari sesleri Premium ile açılır.',
                            style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
                          ),
                          backgroundColor: const Color(0xFF7C3AED),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.all(16),
                          action: SnackBarAction(
                            label: 'Premium',
                            textColor: Colors.white,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() => _selectedReciter = val);
                    Navigator.pop(ctx);
                    _loadSurah();
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: _isDownloaded
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _downloadCurrentSurahForOffline();
                        },
                  icon: Icon(
                    _isDownloaded ? Icons.check_circle_rounded : Icons.download_for_offline_rounded,
                  ),
                  label: Text(
                    _isDownloaded ? 'Offline Ses İndirildi' : 'Offline Ses İndir (Premium)',
                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                  ),
                ),
                if (_isDownloaded) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteCurrentSurahOfflineAudio();
                    },
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text(
                      'İndirilen Sesi Sil',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
                    ),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 140),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark
        ? const Color(0xFF95D3BA)
        : const Color(0xFF003527);
    final bgColor = scheme.surface;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark
                ? scheme.surface.withValues(alpha: 0.95)
                : const Color(0xFFFBF9F5).withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: primaryColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.surahMeta.englishName,
              style: GoogleFonts.notoSerif(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            centerTitle: true,
            actions: [
              // Kaydet / Yer imi
              Tooltip(
                message: _isSaved ? 'Kaydedilenlerden Çıkar' : 'Kaydet',
                child: IconButton(
                  icon: Icon(
                    _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: _isSaved ? const Color(0xFFD97706) : primaryColor,
                  ),
                  onPressed: () async {
                    await AppPreferences.toggleSavedSurah(widget.surahMeta.number);
                    if (mounted) {
                      setState(() {
                        _isSaved = AppPreferences.getSavedSurahs()
                            .contains(widget.surahMeta.number);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isSaved
                                ? '${widget.surahMeta.englishName} kaydedildi.'
                                : '${widget.surahMeta.englishName} kaydedilenlerden çıkarıldı.',
                            style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                          ),
                          backgroundColor: const Color(0xFFD97706),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
              // Tecvid renklendirme toggle
              Tooltip(
                message: _tajweedEnabled ? 'Tecvidi Kapat' : 'Tecvidi Aç',
                child: IconButton(
                  icon: Icon(
                    Icons.color_lens_rounded,
                    color: _tajweedEnabled
                        ? const Color(0xFF10B981)
                        : primaryColor.withValues(alpha: 0.4),
                  ),
                  onPressed: () =>
                      setState(() => _tajweedEnabled = !_tajweedEnabled),
                ),
              ),
              // Legend toggle
              Tooltip(
                message: 'Renk Efsanesi',
                child: IconButton(
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: _showLegend
                        ? const Color(0xFF3B82F6)
                        : primaryColor.withValues(alpha: 0.6),
                  ),
                  onPressed: () =>
                      setState(() => _showLegend = !_showLegend),
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings_rounded, color: primaryColor),
                onPressed: _showSettingsSheet,
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child:
                  AppGlassCard(
                        baseColor: const Color(0xFF064E3B),
                        opacity: 1.0,
                        padding: const EdgeInsets.all(32),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -30,
                              top: -30,
                              child: Icon(
                                Icons.auto_stories_rounded,
                                size: 160,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              AppText.of(context, 'suraLabel'),
                                              style: const TextStyle(
                                                color: Color(0xFFFFDCC3),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2.0,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 24,
                                              height: 1,
                                              color: const Color(0xFFD97706),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          widget.surahMeta.englishName,
                                          style: GoogleFonts.notoSerif(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${widget.surahMeta.numberOfAyahs} Verses',
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            color: Color(0xFF95D3BA),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          widget.surahMeta.name,
                                          style: const TextStyle(
                                            fontFamily: 'Amiri',
                                            fontSize: 36,
                                            color: Color(0xFFFFDCC3),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.surahMeta.revelationType,
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            color: Color(0xFF95D3BA),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fade(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
            ),
          ),

          if (!_isLoading && _error == null && widget.surahMeta.number != 9)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    const Text(
                      'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 32,
                        color: Color(0xFF003527),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rahman ve Rahim olan Allah\'ın adıyla.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 600.ms, delay: 200.ms),
            ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: scheme.error, size: 48),
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: scheme.error)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSurah,
                      child: Text(AppText.of(context, 'retry')),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Tecvid legend (toggle ile göster/gizle)
            if (_showLegend && _tajweedEnabled)
              SliverToBoxAdapter(
                child: TajweedLegend()
                    .animate()
                    .fade(duration: 300.ms)
                    .slideY(begin: -0.1, end: 0),
              ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final ayah = _ayahs[index];
                  return ValueListenableBuilder<_AudioUiState>(
                    valueListenable: _audioUiState,
                    builder: (context, ui, child) {
                      final isPlaying =
                          ui.currentAudioUrl == ayah.trackId && ui.isPlaying;
                      return ValueListenableBuilder<_PlaybackState>(
                        valueListenable: _playbackState,
                        builder: (context, playback, innerChild) {
                          final sameTrack =
                              playback.currentAudioUrl == ayah.trackId;
                          final totalMs = playback.duration.inMilliseconds;
                          final ratio = totalMs <= 0
                              ? 0.0
                              : (playback.position.inMilliseconds / totalMs)
                                    .clamp(0.0, 1.0);
                          return _AyahCard(
                                ayah: ayah,
                                isPlaying: isPlaying,
                                progress: sameTrack ? ratio : 0.0,
                                onPlayPause: () => _playTrack(ayah),
                                tajweedEnabled: _tajweedEnabled,
                              )
                              .animate()
                              .fade(
                                duration: 400.ms,
                                delay: Duration(
                                  milliseconds: (index * 50).clamp(0, 500),
                                ),
                              )
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                curve: Curves.easeOutQuad,
                              );
                        },
                      );
                    },
                  );
                }, childCount: _ayahs.length),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AyahCard extends StatefulWidget {
  const _AyahCard({
    required this.ayah,
    required this.isPlaying,
    required this.progress,
    required this.onPlayPause,
    required this.tajweedEnabled,
  });

  final _AyahBundle ayah;
  final bool isPlaying;
  final double progress;
  final VoidCallback onPlayPause;
  final bool tajweedEnabled;

  @override
  State<_AyahCard> createState() => _AyahCardState();
}

class _AyahCardState extends State<_AyahCard> {
  late List<TajweedSpan> _spans;

  @override
  void initState() {
    super.initState();
    _spans = TajweedEngine.analyze(widget.ayah.arabicText);
  }

  @override
  void didUpdateWidget(_AyahCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ayah.arabicText != widget.ayah.arabicText) {
      _spans = TajweedEngine.analyze(widget.ayah.arabicText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor =
        isDark ? const Color(0xFF95D3BA) : const Color(0xFF003527);
    final secondaryColor =
        isDark ? const Color(0xFFD97706) : const Color(0xFF904D00);

    final cardBg = widget.isPlaying
        ? const Color(0xFF064E3B)
        : (isDark
              ? scheme.surfaceContainerLow
              : scheme.surfaceContainerLowest);

    return AppGlassCard(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      baseColor: cardBg,
      opacity: widget.isPlaying ? 1.0 : 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Başlık satırı ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isPlaying
                      ? secondaryColor
                      : (isDark
                            ? scheme.surfaceContainerHighest
                            : scheme.surfaceContainerHigh),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.ayah.numberInSurah.toString(),
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    color: widget.isPlaying ? Colors.white : scheme.onSurface,
                    fontSize: 12,
                  ),
                ),
              ),
              if (widget.isPlaying)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.graphic_eq, color: secondaryColor, size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'Seslendiriliyor',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                )
              else
                IconButton(
                  onPressed: widget.onPlayPause,
                  icon: Icon(
                    Icons.play_arrow_rounded,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Arapça metin (tecvid renkli + ses senkronu) ────────────────
          InkWell(
            onTap: widget.onPlayPause,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: _TajweedSyncedText(
                spans: _spans,
                progress: widget.progress,
                isPlaying: widget.isPlaying,
                tajweedEnabled: widget.tajweedEnabled,
                defaultColor: widget.isPlaying ? Colors.white : primaryColor,
              ),
            ),
          ),

          // ── İlerleme çubuğu (ses çalarken) ────────────────────────────
          if (widget.isPlaying) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: widget.progress,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Divider(
            color: (widget.isPlaying ? Colors.white : scheme.outlineVariant)
                .withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),

          Text(
            'ANLAM / MEAL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: widget.isPlaying ? const Color(0xFFFFDCC3) : secondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.ayah.translatedText,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              height: 1.6,
              color: widget.isPlaying ? Colors.white : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tecvid renkli + ses ile senkronize Arapça metin widget'ı.
class _TajweedSyncedText extends StatelessWidget {
  const _TajweedSyncedText({
    required this.spans,
    required this.progress,
    required this.isPlaying,
    required this.tajweedEnabled,
    required this.defaultColor,
  });

  final List<TajweedSpan> spans;
  final double progress;
  final bool isPlaying;
  final bool tajweedEnabled;
  final Color defaultColor;

  @override
  Widget build(BuildContext context) {
    final highlightedCount = (spans.length * progress).floor();

    return RichText(
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        children: [
          for (int i = 0; i < spans.length; i++)
            _buildSpan(spans[i], i, highlightedCount),
        ],
      ),
    );
  }

  TextSpan _buildSpan(TajweedSpan span, int index, int highlightedCount) {
    final isHighlighted = isPlaying && index < highlightedCount;
    final isCurrentWord =
        isPlaying && index == highlightedCount && highlightedCount < spans.length;

    Color wordColor;
    if (isHighlighted) {
      wordColor = const Color(0xFFFFD166);
    } else if (tajweedEnabled && span.rule != TajweedRule.none) {
      wordColor = span.rule.ruleColor;
    } else {
      wordColor = defaultColor;
    }

    return TextSpan(
      text: index == spans.length - 1 ? span.text : '${span.text} ',
      style: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 32,
        height: 2.6,
        color: wordColor,
        fontWeight: isHighlighted
            ? FontWeight.bold
            : isCurrentWord
            ? FontWeight.w700
            : FontWeight.w500,
        shadows: isCurrentWord
            ? [
                Shadow(
                  color: const Color(0xFFFFD166).withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ]
            : null,
        backgroundColor: isCurrentWord ? const Color(0xFFFFD166).withValues(alpha: 0.25) : null,
      ),
    );
  }
}

/// Tecvid renk efsanesi (legend) — hangi renk hangi kuralı temsil eder.
class TajweedLegend extends StatelessWidget {
  const TajweedLegend({super.key});

  static const _rules = [
    TajweedRule.ghunna,
    TajweedRule.izhar,
    TajweedRule.idghamGhunna,
    TajweedRule.idghamNoGhunna,
    TajweedRule.ikhfa,
    TajweedRule.iqlab,
    TajweedRule.qalqala,
    TajweedRule.madd,
    TajweedRule.lamShamsi,
    TajweedRule.lamQamari,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.9);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TECVİD RENKLERİ',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: _rules.map((rule) => _LegendItem(rule: rule)).toList(),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.rule});
  final TajweedRule rule;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: rule.ruleColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          rule.ruleLabel,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
