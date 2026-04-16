import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/audio/audio_profile.dart';
import '../../../../core/audio/offline_audio_service.dart';
import '../../../../core/network/app_dio.dart';
import '../../../../core/quran/tajweed_engine.dart';
import '../../../../core/settings/app_preferences.dart';
import '../../../../core/widgets/app_glass_card.dart';
import 'quran_reading_page.dart' show TajweedLegend;

// ── Cüz içindeki bir ayetin tüm verisi ──────────────────────────────────────

class _AyahBundle {
  const _AyahBundle({
    required this.trackId,
    required this.surahNumber,
    required this.surahName,
    required this.numberInSurah,
    required this.arabicText,
    required this.translatedText,
    required this.audioUrl,
  });
  final String trackId;
  final int surahNumber;
  final String surahName;
  final int numberInSurah;
  final String arabicText;
  final String translatedText;
  final String audioUrl;
}

class _AudioUiState {
  const _AudioUiState({required this.currentTrackId, required this.isPlaying});
  final String? currentTrackId;
  final bool isPlaying;
}

class _PlaybackState {
  const _PlaybackState({
    required this.currentTrackId,
    required this.position,
    required this.duration,
  });
  final String? currentTrackId;
  final Duration position;
  final Duration duration;
}

// ── Sayfa ────────────────────────────────────────────────────────────────────

class JuzReadingPage extends ConsumerStatefulWidget {
  const JuzReadingPage({super.key, required this.juzNumber});
  final int juzNumber;

  @override
  ConsumerState<JuzReadingPage> createState() => _JuzReadingPageState();
}

class _JuzReadingPageState extends ConsumerState<JuzReadingPage> {
  Dio? _dio;
  OfflineAudioService? _offlineAudioService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  bool _isLoading = true;
  String? _error;
  List<_AyahBundle> _ayahs = const [];

  String _selectedLanguage = 'Türkçe';
  AudioProfile _selectedProfile = AudioProfile.male;
  String _selectedReciter = 'ar.alafasy';
  bool _tajweedEnabled = true;
  bool _showLegend = false;

  final ValueNotifier<_AudioUiState> _audioUiState = ValueNotifier(
    const _AudioUiState(currentTrackId: null, isPlaying: false),
  );
  final ValueNotifier<_PlaybackState> _playbackState = ValueNotifier(
    const _PlaybackState(
      currentTrackId: null,
      position: Duration.zero,
      duration: Duration.zero,
    ),
  );

  Timer? _readingTimer;

  static const _languageToEdition = <String, String>{
    'Türkçe': 'tr.diyanet',
    'English': 'en.asad',
    'Français': 'fr.hamidullah',
    'العربية': 'ar.muyassar',
    'اردو': 'ur.jalandhry',
    'Bahasa Indonesia': 'id.indonesian',
    'Deutsch': 'de.aburida',
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

      _tts.setCompletionHandler(() {
        final completedId = _audioUiState.value.currentTrackId;
        _audioUiState.value = _AudioUiState(
          currentTrackId: completedId,
          isPlaying: false,
        );
        Future.microtask(() {
          _playNextAfterCurrent(completedId);
        });
      });
      _tts.setProgressHandler((text, startOffset, endOffset, word) {
        final cur = _audioUiState.value.currentTrackId;
        if (cur != null && text.isNotEmpty) {
           final ratio = (endOffset / text.length).clamp(0.0, 1.0);
           final dur = const Duration(milliseconds: 10000);
           final pos = Duration(milliseconds: (10000 * ratio).toInt());
           _playbackState.value = _PlaybackState(
              currentTrackId: cur,
              position: pos,
              duration: dur,
           );
        }
      });

      _loadJuz();

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          final completedId = _audioUiState.value.currentTrackId;
          _audioUiState.value = _AudioUiState(
            currentTrackId: completedId,
            isPlaying: false,
          );
          _playbackState.value = _PlaybackState(
            currentTrackId: completedId,
            position: Duration.zero,
            duration: _playbackState.value.duration,
          );
          Future.microtask(() {
            _playNextAfterCurrent(completedId);
          });
        }
      });
      _audioPlayer.positionStream.listen((position) {
        _playbackState.value = _PlaybackState(
          currentTrackId: _playbackState.value.currentTrackId,
          position: position,
          duration: _playbackState.value.duration,
        );
      });
      _audioPlayer.durationStream.listen((duration) {
        _playbackState.value = _PlaybackState(
          currentTrackId: _playbackState.value.currentTrackId,
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

  Future<void> _loadJuz() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _audioPlayer.pause();
    } catch (_) {}
    _audioUiState.value = const _AudioUiState(currentTrackId: null, isPlaying: false);

    try {
      final translationEdition = _languageToEdition[_selectedLanguage] ?? 'tr.diyanet';
      final reciterEdition = _selectedProfile == AudioProfile.female
          ? 'ar.hanirifai'
          : _selectedReciter;
      final dio = _dio;
      if (dio == null) return;

      final cacheKey = 'juz_${widget.juzNumber}_${translationEdition}_$reciterEdition';
      final box = Hive.box('quran_cache');

      List<_AyahBundle> bundles = [];

      final cachedStr = box.get(cacheKey);
      if (cachedStr != null && cachedStr is String) {
        final decoded = jsonDecode(cachedStr) as Map<String, dynamic>;
        bundles = _parseBundles(decoded);
      } else {
        final results = await Future.wait<dynamic>([
          dio.get<Map<String, dynamic>>(
            '/juz/${widget.juzNumber}/quran-uthmani',
          ),
          dio.get<Map<String, dynamic>>(
            '/juz/${widget.juzNumber}/$translationEdition',
          ),
          dio.get<Map<String, dynamic>>(
            '/juz/${widget.juzNumber}/$reciterEdition',
          ),
        ]);

        final arabicData = (results[0] as Response<Map<String, dynamic>>).data;
        final translationData = (results[1] as Response<Map<String, dynamic>>).data;
        final audioData = (results[2] as Response<Map<String, dynamic>>).data;

        final arabicAyahs = (arabicData?['data']?['ayahs'] as List<dynamic>? ?? []);
        final translationAyahs = (translationData?['data']?['ayahs'] as List<dynamic>? ?? []);
        final audioAyahs = (audioData?['data']?['ayahs'] as List<dynamic>? ?? []);

        final audioByNumber = <int, String>{};
        for (final a in audioAyahs.whereType<Map>()) {
          final map = a.cast<String, dynamic>();
          final raw = map['number'];
          final ayahNum = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
          final url = map['audio']?.toString();
          if (ayahNum != null && url != null && url.isNotEmpty) {
            audioByNumber[ayahNum] = url;
          }
        }

        final translationByNumber = <int, String>{};
        for (final t in translationAyahs.whereType<Map>()) {
          final map = t.cast<String, dynamic>();
          final raw = map['number'];
          final ayahNum = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
          final text = map['text']?.toString();
          if (ayahNum != null && text != null) {
            translationByNumber[ayahNum] = text;
          }
        }

        final cacheData = <String, dynamic>{
          'arabic': arabicAyahs,
          'translation': translationByNumber.map((k, v) => MapEntry(k.toString(), v)),
          'audio': audioByNumber.map((k, v) => MapEntry(k.toString(), v)),
        };
        await box.put(cacheKey, jsonEncode(cacheData));

        for (final ar in arabicAyahs.whereType<Map>()) {
          final map = ar.cast<String, dynamic>();
          final rawN = map['number'];
          final globalNumber = rawN is int ? rawN : (int.tryParse(rawN?.toString() ?? '') ?? 0);
          final rawNis = map['numberInSurah'];
          final numberInSurah = rawNis is int ? rawNis : (int.tryParse(rawNis?.toString() ?? '') ?? 0);
          final surahMap = (map['surah'] as Map?)?.cast<String, dynamic>() ?? {};
          final rawSN = surahMap['number'];
          final surahNumber = rawSN is int ? rawSN : (int.tryParse(rawSN?.toString() ?? '') ?? 0);
          final surahName = surahMap['englishName']?.toString() ?? '';
          bundles.add(_AyahBundle(
            trackId: 'juz-$globalNumber',
            surahNumber: surahNumber,
            surahName: surahName,
            numberInSurah: numberInSurah,
            arabicText: map['text']?.toString() ?? '',
            translatedText: translationByNumber[globalNumber] ?? '',
            audioUrl: audioByNumber[globalNumber] ?? '',
          ));
        }
      }

      if (mounted) {
        setState(() {
          _ayahs = bundles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Cüz yüklenemedi. İnternet bağlantınızı kontrol edin.';
        });
      }
    }
  }

  List<_AyahBundle> _parseBundles(Map<String, dynamic> data) {
    final arabicAyahs = (data['arabic'] as List<dynamic>? ?? []);
    final translationMap = (data['translation'] as Map<String, dynamic>? ?? {});
    final audioMap = (data['audio'] as Map<String, dynamic>? ?? {});

    final bundles = <_AyahBundle>[];
    for (final ar in arabicAyahs.whereType<Map>()) {
      final map = ar.cast<String, dynamic>();
      final rawNum = map['number'];
      final globalNumber = rawNum is int ? rawNum : (int.tryParse(rawNum?.toString() ?? '') ?? 0);
      final rawNis = map['numberInSurah'];
      final numberInSurah = rawNis is int ? rawNis : (int.tryParse(rawNis?.toString() ?? '') ?? 0);
      final surahMap = (map['surah'] as Map?)?.cast<String, dynamic>() ?? {};
      final rawSurahNum = surahMap['number'];
      final surahNumber = rawSurahNum is int ? rawSurahNum : (int.tryParse(rawSurahNum?.toString() ?? '') ?? 0);
      final surahName = surahMap['englishName']?.toString() ?? '';
      bundles.add(_AyahBundle(
        trackId: 'juz-$globalNumber',
        surahNumber: surahNumber,
        surahName: surahName,
        numberInSurah: numberInSurah,
        arabicText: map['text']?.toString() ?? '',
        translatedText: translationMap[globalNumber.toString()] ?? '',
        audioUrl: audioMap[globalNumber.toString()] ?? '',
      ));
    }
    return bundles;
  }

  Future<void> _playTrack(_AyahBundle track) async {
    try {
      final ui = _audioUiState.value;
      final isSame = ui.currentTrackId == track.trackId;

      if (isSame && ui.isPlaying) {
        await _tts.stop();
        await _audioPlayer.pause();
        _audioUiState.value = _AudioUiState(currentTrackId: track.trackId, isPlaying: false);
        return;
      }
      if (isSame && !ui.isPlaying) {
        await _audioPlayer.play();
        _audioUiState.value = _AudioUiState(currentTrackId: track.trackId, isPlaying: true);
        return;
      }

      await _tts.stop();
      await _audioPlayer.stop();
      _audioUiState.value = _AudioUiState(currentTrackId: track.trackId, isPlaying: false);
      _playbackState.value = const _PlaybackState(
        currentTrackId: null,
        position: Duration.zero,
        duration: Duration.zero,
      );

      var played = false;
      if (track.audioUrl.isNotEmpty) {
        try {
          final offline = _offlineAudioService == null
              ? null
              : await _offlineAudioService!.getCachedFile(
                  track.audioUrl,
                  _selectedProfile,
                );
          if (offline != null) {
            await _audioPlayer.setFilePath(offline.path);
            played = true;
          } else {
            await _audioPlayer.setUrl(track.audioUrl);
            played = true;
          }
        } catch (_) {}
      }

      if (!played &&
          _selectedProfile == AudioProfile.female &&
          track.arabicText.trim().isNotEmpty) {
        await _tts.setLanguage('ar');
        await _tts.setSpeechRate(0.42);
        await _tts.setPitch(1.2);
        await _tts.speak(track.arabicText);
        _audioUiState.value = _AudioUiState(currentTrackId: track.trackId, isPlaying: true);
        _playbackState.value = _PlaybackState(
          currentTrackId: track.trackId,
          position: Duration.zero,
          duration: const Duration(milliseconds: 10000),
        );
        return;
      }

      if (!played) throw Exception('no-audio');

      await _audioPlayer.play();
      _audioUiState.value = _AudioUiState(currentTrackId: track.trackId, isPlaying: true);
      _playbackState.value = _PlaybackState(
        currentTrackId: track.trackId,
        position: Duration.zero,
        duration: _playbackState.value.duration,
      );
      _playbackState.value = _PlaybackState(
        currentTrackId: track.trackId,
        position: Duration.zero,
        duration: _playbackState.value.duration,
      );
    } catch (_) {
      // Playback failed. Automatically attempt next track to resume flow
      _audioUiState.value = const _AudioUiState(currentTrackId: null, isPlaying: false);
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _playNextAfterCurrent(track.trackId);
        });
      }
    }
  }

  void _playNextAfterCurrent(String? completedTrackId) {
    if (completedTrackId == null || _ayahs.isEmpty) return;
    final idx = _ayahs.indexWhere((a) => a.trackId == completedTrackId);
    if (idx >= 0 && idx < _ayahs.length - 1) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _playTrack(_ayahs[idx + 1]);
      });
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
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                106 + MediaQuery.of(ctx).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Okuma Ayarları',
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: _languageToEdition.keys
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLanguage = val);
                        Navigator.pop(ctx);
                        _loadJuz();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProfile.value,
                    decoration: InputDecoration(
                      labelText: 'Ses Profili',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                      _loadJuz();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedProfile == AudioProfile.male) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedReciter,
                      decoration: InputDecoration(
                        labelText: 'Kari Sesi',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                                ),
                              ),
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
                            const SnackBar(
                              content: Text(
                                'Tüm kari sesleri Premium ile açılır.',
                                style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
                              ),
                              backgroundColor: Color(0xFF7C3AED),
                            ),
                          );
                          return;
                        }
                        setState(() => _selectedReciter = val);
                        Navigator.pop(ctx);
                        _loadJuz();
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 140),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF95D3BA) : const Color(0xFF003527);

    return Scaffold(
      backgroundColor: scheme.surface,
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
              'Cüz ${widget.juzNumber}',
              style: GoogleFonts.notoSerif(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            centerTitle: true,
            actions: [
              Tooltip(
                message: _tajweedEnabled ? 'Tecvidi Kapat' : 'Tecvidi Aç',
                child: IconButton(
                  icon: Icon(
                    Icons.color_lens_rounded,
                    color: _tajweedEnabled
                        ? const Color(0xFF10B981)
                        : primaryColor.withValues(alpha: 0.4),
                  ),
                  onPressed: () => setState(() => _tajweedEnabled = !_tajweedEnabled),
                ),
              ),
              Tooltip(
                message: 'Renk Efsanesi',
                child: IconButton(
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: _showLegend
                        ? const Color(0xFF3B82F6)
                        : primaryColor.withValues(alpha: 0.6),
                  ),
                  onPressed: () => setState(() => _showLegend = !_showLegend),
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings_rounded, color: primaryColor),
                onPressed: _showSettingsSheet,
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Hero banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: AppGlassCard(
                baseColor: const Color(0xFF064E3B),
                opacity: 1.0,
                padding: const EdgeInsets.all(32),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'CÜZ',
                              style: TextStyle(
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
                          '${widget.juzNumber}. Cüz',
                          style: GoogleFonts.notoSerif(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLoading
                              ? 'Yükleniyor...'
                              : '${_ayahs.length} Ayet',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF95D3BA),
                            fontWeight: FontWeight.w600,
                          ),
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
                      onPressed: _loadJuz,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ayah = _ayahs[index];

                    // Sure başlığı: bir önceki ayetten farklı sure ise göster
                    final showSurahHeader = index == 0 ||
                        _ayahs[index - 1].surahNumber != ayah.surahNumber;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showSurahHeader)
                          Padding(
                            padding: EdgeInsets.only(bottom: 12, top: index == 0 ? 0 : 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF064E3B).withValues(alpha: isDark ? 0.5 : 0.15),
                                    const Color(0xFF065F46).withValues(alpha: isDark ? 0.3 : 0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${ayah.surahNumber}',
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    ayah.surahName,
                                    style: GoogleFonts.notoSerif(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF95D3BA)
                                          : const Color(0xFF064E3B),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fade(duration: 300.ms),
                          ),
                        ValueListenableBuilder<_AudioUiState>(
                          valueListenable: _audioUiState,
                          builder: (context, ui, _) {
                            final isPlaying =
                                ui.currentTrackId == ayah.trackId && ui.isPlaying;
                            return ValueListenableBuilder<_PlaybackState>(
                              valueListenable: _playbackState,
                              builder: (context, playback, _) {
                                final sameTrack = playback.currentTrackId == ayah.trackId;
                                final totalMs = playback.duration.inMilliseconds;
                                final ratio = totalMs <= 0
                                    ? 0.0
                                    : (playback.position.inMilliseconds / totalMs)
                                        .clamp(0.0, 1.0);
                                return _JuzAyahCard(
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
                                        milliseconds: (index * 30).clamp(0, 400),
                                      ),
                                    )
                                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuad);
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                  childCount: _ayahs.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Ayet Kartı ───────────────────────────────────────────────────────────────

class _JuzAyahCard extends StatefulWidget {
  const _JuzAyahCard({
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
  State<_JuzAyahCard> createState() => _JuzAyahCardState();
}

class _JuzAyahCardState extends State<_JuzAyahCard> {
  late List<TajweedSpan> _spans;

  @override
  void initState() {
    super.initState();
    _spans = TajweedEngine.analyze(widget.ayah.arabicText);
  }

  @override
  void didUpdateWidget(_JuzAyahCard old) {
    super.didUpdateWidget(old);
    if (old.ayah.arabicText != widget.ayah.arabicText) {
      _spans = TajweedEngine.analyze(widget.ayah.arabicText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF95D3BA) : const Color(0xFF003527);
    final secondaryColor = isDark ? const Color(0xFFD97706) : const Color(0xFF904D00);

    final cardBg = widget.isPlaying
        ? const Color(0xFF064E3B)
        : (isDark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest);

    return AppGlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      baseColor: cardBg,
      opacity: widget.isPlaying ? 1.0 : 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
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
                    fontSize: 13,
                    color: widget.isPlaying ? Colors.white : primaryColor,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onPlayPause,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.isPlaying
                        ? const Color(0xFFD97706)
                        : primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: widget.isPlaying ? Colors.white : primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          if (widget.isPlaying && widget.progress > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: widget.progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
              borderRadius: BorderRadius.circular(4),
            ),
          ],

          const SizedBox(height: 16),

          // Arapça metin
          if (widget.tajweedEnabled && _spans.isNotEmpty)
            Directionality(
              textDirection: TextDirection.rtl,
              child: RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  children: _spans.asMap().entries.map((entry) {
                    final s = entry.value;
                    final defaultColor = widget.isPlaying
                        ? Colors.white
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF1A1A2E));
                    final wordColor = s.rule != TajweedRule.none
                        ? s.rule.ruleColor
                        : defaultColor;
                    return TextSpan(
                      text: entry.key == _spans.length - 1 ? s.text : '${s.text} ',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 26,
                        height: 2.4,
                        color: wordColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
            )
          else
            Text(
              widget.ayah.arabicText,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 26,
                height: 2.4,
                color: widget.isPlaying
                    ? Colors.white
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF1A1A2E)),
              ),
            ),

          if (widget.ayah.translatedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: widget.isPlaying
                  ? Colors.white.withValues(alpha: 0.15)
                  : scheme.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              widget.ayah.translatedText,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                height: 1.65,
                color: widget.isPlaying
                    ? Colors.white.withValues(alpha: 0.85)
                    : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
