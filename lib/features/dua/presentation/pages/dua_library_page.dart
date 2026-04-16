import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/audio/audio_profile.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/settings/app_preferences.dart';
import '../../../../core/widgets/app_side_panel.dart';

class DuaLibraryPage extends StatefulWidget {
  const DuaLibraryPage({super.key});

  @override
  State<DuaLibraryPage> createState() => _DuaLibraryPageState();
}

class _DuaItem {
  const _DuaItem({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
    required this.arabic,
    required this.transliteration,
  });
  final String id;
  final String titleKey;
  final String bodyKey;
  final String arabic;
  final String transliteration;
}

class _DuaLibraryPageState extends State<DuaLibraryPage> {
  final _searchController = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  String _query = '';
  final Set<String> _favorites = <String>{};
  String? _playingTitle;
  AudioProfile _selectedVoice = AudioProfile.male;
  int _selectedTab = 0;

  // TTS progress tracking
  double _ttsProgress = 0.0;
  List<Map<dynamic, dynamic>> _cachedVoices = [];

  @override
  void initState() {
    super.initState();
    final stored =
        AppPreferences.box.get(
              'dua_voice',
              defaultValue: AudioProfile.male.value,
            )
            as String;
    _selectedVoice = AudioProfile.fromValue(stored);
    // Force male voice if not premium
    if (!AppPreferences.isPremiumEnabled() && _selectedVoice == AudioProfile.female) {
      _selectedVoice = AudioProfile.male;
      AppPreferences.box.put('dua_voice', AudioProfile.male.value);
    }
    const legacyTitleToId = {
      'Sabah Zikri': 'g0',
      'Akşam Zikri': 'g1',
      'Yolculuk Duası': 'g2',
      'Yemeğe Başlarken': 'g3',
      'Yemekten Sonra': 'g4',
      'Hastalık Duası': 'g5',
      'İstiğfar': 'g6',
      'Ayetel Kürsi': 'g7',
      'İhlas': 'g8',
      'Sübhaneke': 'p0',
      'Rükû Duası': 'p1',
      'Secde Duası': 'p2',
      'Ettehiyyatü': 'p3',
      'Allahümme Salli': 'p4',
      'Allahümme Barik': 'p5',
      'Rabbena Atina': 'p6',
      'Kunut Duası': 'p7',
      'Namaz Sonrası Tesbihat': 'p8',
      'Rabbena La Tuzigh': 'q1',
      'Rabbena Hab Lena': 'q2',
      'Hasbunallahu ve Ni’mel Vekil': 'q3',
      'Rabbena Zalemna': 'q4',
      'La İlahe İlla Ente': 'q5',
      'Rabbic Alni Mukimes Salat': 'q6',
      'Rabbi Zidni İlma': 'q7',
      'Rabbena Efriğ Aleyna Sabran': 'q8',
      'Rabbena İftah Beynena': 'q9',
      'Rabbena La Tecalna Fitneten': 'q10',
      'Rabbi İnni Lima Enzelte': 'q11',
      'Rabbi Euzubike Min Hemezat': 'q12',
      'Rabbiğfir Verham': 'q13',
      'Rabbena Heb Lena Min Ezvacina': 'q14',
      'Rabbenağfirli Ve Li Valideyye': 'q15',
      'Rabbena Efrığ Aleyna Sabran': 'q16',
      'Rabbena İnnena Semina Münadiyen': 'q17',
      'Rabbena Alemna Enfüsena': 'q18',
      'Rabbena Etmim Lena Nurena': 'q19',
    };
    final idBox = AppPreferences.box.get('favorite_dua_ids', defaultValue: <String>[]) as List<dynamic>;
    final ids = idBox.whereType<String>().toSet();
    if (ids.isEmpty) {
      final old = AppPreferences.box.get('favorite_duas', defaultValue: <String>[]) as List<dynamic>;
      for (final t in old.whereType<String>()) {
        final mid = legacyTitleToId[t];
        if (mid != null) ids.add(mid);
      }
      if (ids.isNotEmpty) {
        AppPreferences.box.put('favorite_dua_ids', ids.toList());
        AppPreferences.box.delete('favorite_duas');
      }
    }
    _favorites.addAll(ids);

    // Cache voices once at startup to avoid blocking _speak
    _tts.getVoices.then((voices) {
      if (voices is List) {
        _cachedVoices = voices.whereType<Map>().cast<Map<dynamic, dynamic>>().toList();
      }
    });

    // TTS callbacks for progress tracking
    _tts.setProgressHandler((text, start, end, word) {
      if (!mounted) return;
      final wordCount = text.split(' ').length;
      final textBefore = text.substring(0, start);
      final wordIndex = textBefore.split(' ').length;
      setState(() {
        _ttsProgress = wordCount > 0 ? (wordIndex / wordCount).clamp(0.0, 1.0) : 0.0;
      });
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _playingTitle = null;
        _ttsProgress = 0.0;
      });
    });
    _tts.setCancelHandler(() {
      if (!mounted) return;
      setState(() => _ttsProgress = 0.0);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _searchController.dispose();
    super.dispose();
  }

  static const _generalDuas = <_DuaItem>[
    _DuaItem(
      id: 'g0',
      titleKey: 'dua_g0_t',
      bodyKey: 'dua_g0_b',
      arabic:
          'أَصْـبَحْنا وَأَصْـبَحَ المُـلكُ للهِ رَبِّ العالَمينَ، اللّهُـمَّ إِنِّي أَسْأَلُـكَ خَـيْرَ هذا اليومِ',
      transliteration:
          'Asbahna wa asbahal mulku lillah rabbil alemin, Allahumme inni es’eluke hayra hazel yevm.',
    ),
    _DuaItem(
      id: 'g1',
      titleKey: 'dua_g1_t',
      bodyKey: 'dua_g1_b',
      arabic:
          'أَمْسَيْـنا وَأَمْسَى المُـلكُ للهِ رَبِّ العالَمينَ، اللّهُـمَّ إِنِّي أَسْأَلُـكَ خَـيْرَ هذِه الليلةِ',
      transliteration:
          'Amsayna wa amsal mulku lillah rabbil alemin, Allahumme inni es’eluke hayra hazihilleyle.',
    ),
    _DuaItem(
      id: 'g2',
      titleKey: 'dua_g2_t',
      bodyKey: 'dua_g2_b',
      arabic:
          'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَىٰ رَبِّنَا لَمُنقَلِبُونَ',
      transliteration:
          'Subhanellezi sehhara lena haza ve ma kunna lehu mukrinin ve inna ila rabbina lemunkalibun.',
    ),
    _DuaItem(
      id: 'g3',
      titleKey: 'dua_g3_t',
      bodyKey: 'dua_g3_b',
      arabic: 'بِسْمِ الله',
      transliteration: 'Bismillah',
    ),
    _DuaItem(
      id: 'g4',
      titleKey: 'dua_g4_t',
      bodyKey: 'dua_g4_b',
      arabic: 'الْحَمْدُ لِلَّهِ',
      transliteration: 'Elhamdülillah',
    ),
    _DuaItem(
      id: 'g5',
      titleKey: 'dua_g5_t',
      bodyKey: 'dua_g5_b',
      arabic:
          'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ البَأْسَ اشْفِ أَنْتَ الشَّافِي لا شِفَاءَ إِلاَّ شِفَاؤُكَ شِفَاءً لا يُغَادِرُ سَقَمًا',
      transliteration:
          'Allahumme rabben nasi ezhibil be’s, işfi enteş-şafi, la şifae illa şifauke, şifaen la yugadiru sekama.',
    ),
    _DuaItem(
      id: 'g6',
      titleKey: 'dua_g6_t',
      bodyKey: 'dua_g6_b',
      arabic: 'أَسْتَغْفِرُ اللّٰهَ',
      transliteration: 'Estağfirullah',
    ),
    _DuaItem(
      id: 'g7',
      titleKey: 'dua_g7_t',
      bodyKey: 'dua_g7_b',
      arabic:
          'اللّٰهُ لَٓا اِلٰهَ اِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْاَرْضِ',
      transliteration: 'Allahu la ilahe illa huvel hayyul kayyum',
    ),
    _DuaItem(
      id: 'g8',
      titleKey: 'dua_g8_t',
      bodyKey: 'dua_g8_b',
      arabic: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
      transliteration: 'Kul huvallahu ehad',
    ),
  ];

  Future<void> _speak(_DuaItem item) async {
    if (_playingTitle == item.id) {
      await _tts.stop();
      if (mounted) {
        setState(() {
          _playingTitle = null;
          _ttsProgress = 0.0;
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _ttsProgress = 0.0);
    }
    await _tts.stop();
    await _tts.setLanguage('ar');
    // Force male voice if not premium (safety check)
    final effectiveVoice = (!AppPreferences.isPremiumEnabled() && _selectedVoice == AudioProfile.female)
        ? AudioProfile.male
        : _selectedVoice;
    if (_cachedVoices.isNotEmpty) {
      Map<dynamic, dynamic>? selected;
      final isMale = effectiveVoice == AudioProfile.male;
      for (final voice in _cachedVoices) {
        final name = (voice['name'] ?? '').toString().toLowerCase();
        if (isMale && (name.contains('male') || name.contains('erkek'))) {
          selected = voice;
          break;
        }
        if (!isMale &&
            (name.contains('female') ||
                name.contains('kadin') ||
                name.contains('woman'))) {
          selected = voice;
          break;
        }
      }
      if (selected != null) {
        await _tts.setVoice({
          'name': selected['name'],
          'locale': selected['locale'],
        });
      }
    }
    await _tts.setPitch(effectiveVoice == AudioProfile.male ? 0.7 : 1.2);
    await _tts.setSpeechRate(0.4);
    if (mounted) {
      setState(() => _playingTitle = item.id);
    }
    AppPreferences.incrementDuaPlayCount();
    await _tts.speak(item.arabic);
  }

  static const _prayerDuas = <_DuaItem>[
    _DuaItem(
      id: 'p0',
      titleKey: 'dua_p0_t',
      bodyKey: 'dua_p0_b',
      arabic: 'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ',
      transliteration: 'Subhaneke Allahumme ve bihamdik',
    ),
    _DuaItem(
      id: 'p1',
      titleKey: 'dua_p1_t',
      bodyKey: 'dua_p1_b',
      arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
      transliteration: 'Subhane rabbiyel azim',
    ),
    _DuaItem(
      id: 'p2',
      titleKey: 'dua_p2_t',
      bodyKey: 'dua_p2_b',
      arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
      transliteration: 'Subhane rabbiyel a’la',
    ),
    _DuaItem(
      id: 'p3',
      titleKey: 'dua_p3_t',
      bodyKey: 'dua_p3_b',
      arabic: 'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ',
      transliteration: 'Ettehiyyatu lillahi vessalevatu vettayyibat',
    ),
    _DuaItem(
      id: 'p4',
      titleKey: 'dua_p4_t',
      bodyKey: 'dua_p4_b',
      arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
      transliteration: 'Allahumme salli ala Muhammed',
    ),
    _DuaItem(
      id: 'p5',
      titleKey: 'dua_p5_t',
      bodyKey: 'dua_p5_b',
      arabic: 'اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ',
      transliteration: 'Allahumme barik ala Muhammed',
    ),
    _DuaItem(
      id: 'p6',
      titleKey: 'dua_p6_t',
      bodyKey: 'dua_p6_b',
      arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً',
      transliteration: 'Rabbena atina fiddunya haseneten',
    ),
    _DuaItem(
      id: 'p7',
      titleKey: 'dua_p7_t',
      bodyKey: 'dua_p7_b',
      arabic: 'اللَّهُمَّ إِنَّا نَسْتَعِينُكَ',
      transliteration: 'Allahumme inna nesta’inuke',
    ),
    _DuaItem(
      id: 'p8',
      titleKey: 'dua_p8_t',
      bodyKey: 'dua_p8_b',
      arabic:
          'سُبْحَانَ ٱللَّٰهِ ٣٣، ٱلْحَمْدُ لِلَّٰهِ ٣٣، ٱللَّٰهُ أَكْبَرُ ٣٤',
      transliteration: 'Subhanallah 33, Elhamdülillah 33, Allahu Ekber 34',
    ),
  ];

  static const _quranDuas = <_DuaItem>[
    _DuaItem(
      id: 'q0',
      titleKey: 'dua_q0_t',
      bodyKey: 'dua_q0_b',
      arabic:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً',
      transliteration:
          'Rabbena atina fid-dunya hasaneten ve fil-ahireti hasaneten',
    ),
    _DuaItem(
      id: 'q1',
      titleKey: 'dua_q1_t',
      bodyKey: 'dua_q1_b',
      arabic: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا',
      transliteration: 'Rabbena la tuzigh qulubena ba’de iz hedeytena',
    ),
    _DuaItem(
      id: 'q2',
      titleKey: 'dua_q2_t',
      bodyKey: 'dua_q2_b',
      arabic: 'رَبَّنَا هَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً',
      transliteration: 'Rabbena hab lena min ledunke rahmeh',
    ),
    _DuaItem(
      id: 'q3',
      titleKey: 'dua_q3_t',
      bodyKey: 'dua_q3_b',
      arabic: 'حَسْبُنَا ٱللَّٰهُ وَنِعْمَ ٱلْوَكِيلُ',
      transliteration: 'Hasbunallahu ve ni’mel vekil',
    ),
    _DuaItem(
      id: 'q4',
      titleKey: 'dua_q4_t',
      bodyKey: 'dua_q4_b',
      arabic: 'رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا',
      transliteration: 'Rabbena zalemna enfusena ve in lem tağfir lena',
    ),
    _DuaItem(
      id: 'q5',
      titleKey: 'dua_q5_t',
      bodyKey: 'dua_q5_b',
      arabic:
          'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      transliteration: 'La ilahe illa ente subhaneke inni kuntu minez-zalimin',
    ),
    _DuaItem(
      id: 'q6',
      titleKey: 'dua_q6_t',
      bodyKey: 'dua_q6_b',
      arabic: 'رَبِّ ٱجْعَلْنِي مُقِيمَ ٱلصَّلَاةِ وَمِن ذُرِّيَّتِي',
      transliteration: 'Rabbi’c-alni mukimes-salati ve min zürriyyeti',
    ),
    _DuaItem(
      id: 'q7',
      titleKey: 'dua_q7_t',
      bodyKey: 'dua_q7_b',
      arabic: 'رَبِّ زِدْنِي عِلْمًا',
      transliteration: 'Rabbi zidni ilma',
    ),
    _DuaItem(
      id: 'q8',
      titleKey: 'dua_q8_t',
      bodyKey: 'dua_q8_b',
      arabic: 'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَتَوَفَّنَا مُسْلِمِينَ',
      transliteration: 'Rabbena efriğ aleyna sabran ve teveffena müslimin',
    ),
    _DuaItem(
      id: 'q9',
      titleKey: 'dua_q9_t',
      bodyKey: 'dua_q9_b',
      arabic: 'رَبَّنَا ٱفْتَحْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِٱلْحَقِّ',
      transliteration: 'Rabbena iftah beynena ve beyne kavmina bil-hakk',
    ),
    _DuaItem(
      id: 'q10',
      titleKey: 'dua_q10_t',
      bodyKey: 'dua_q10_b',
      arabic: 'رَبَّنَا لَا تَجْعَلْنَا فِتْنَةً لِّلْقَوْمِ ٱلظَّالِمِينَ',
      transliteration: 'Rabbena la tec’alna fitneten lil-kavmiz-zalimin',
    ),
    _DuaItem(
      id: 'q11',
      titleKey: 'dua_q11_t',
      bodyKey: 'dua_q11_b',
      arabic: 'رَبِّ إِنِّي لِمَا أَنزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
      transliteration: 'Rabbi inni lima enzelte ileyye min hayrin fakir',
    ),
    _DuaItem(
      id: 'q12',
      titleKey: 'dua_q12_t',
      bodyKey: 'dua_q12_b',
      arabic: 'رَبِّ أَعُوذُ بِكَ مِنْ هَمَزَاتِ ٱلشَّيَاطِينِ',
      transliteration: 'Rabbi euzü bike min hemezatiş-şeyatin',
    ),
    _DuaItem(
      id: 'q13',
      titleKey: 'dua_q13_t',
      bodyKey: 'dua_q13_b',
      arabic: 'رَبِّ ٱغْفِرْ وَٱرْحَمْ وَأَنتَ خَيْرُ ٱلرَّاحِمِينَ',
      transliteration: 'Rabbiğfir verham ve ente hayrur-rahimin',
    ),
    _DuaItem(
      id: 'q14',
      titleKey: 'dua_q14_t',
      bodyKey: 'dua_q14_b',
      arabic:
          'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ',
      transliteration:
          'Rabbena heb lena min ezvacina ve zürriyyatina kurrete ayun',
    ),
    _DuaItem(
      id: 'q15',
      titleKey: 'dua_q15_t',
      bodyKey: 'dua_q15_b',
      arabic: 'رَبَّنَا ٱغْفِرْ لِي وَلِوَٰلِدَيَّ وَلِلْمُؤْمِنِينَ',
      transliteration: 'Rabbenağfir li ve li valideyye velil müminin',
    ),
    _DuaItem(
      id: 'q16',
      titleKey: 'dua_q16_t',
      bodyKey: 'dua_q16_b',
      arabic: 'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا',
      transliteration: 'Rabbena efrığ aleyna sabran ve sebbid akdamena',
    ),
    _DuaItem(
      id: 'q17',
      titleKey: 'dua_q17_t',
      bodyKey: 'dua_q17_b',
      arabic: 'رَبَّنَا إِنَّنَا سَمِعْنَا مُنَادِيًا يُنَادِي لِلْإِيمَانِ',
      transliteration: 'Rabbena innena semi’na münadiyen yunadi lil-iman',
    ),
    _DuaItem(
      id: 'q18',
      titleKey: 'dua_q18_t',
      bodyKey: 'dua_q18_b',
      arabic: 'رَبَّنَا ظَلَمْنَا أَنْفُسَنَا',
      transliteration: 'Rabbena zalemna enfusena',
    ),
    _DuaItem(
      id: 'q19',
      titleKey: 'dua_q19_t',
      bodyKey: 'dua_q19_b',
      arabic: 'رَبَّنَا أَتْمِمْ لَنَا نُورَنَا وَٱغْفِرْ لَنَا',
      transliteration: 'Rabbena etmim lena nurena vağfir lena',
    ),
  ];

  List<_DuaItem> _filter(BuildContext context, List<_DuaItem> input) {
    if (_query.isEmpty) {
      return input;
    }
    final q = _query.toLowerCase();
    return input.where((item) {
      final title = AppText.of(context, item.titleKey).toLowerCase();
      final body = AppText.of(context, item.bodyKey).toLowerCase();
      return title.contains(q) ||
          body.contains(q) ||
          item.arabic.contains(_query) ||
          item.transliteration.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final general = _filter(context, _generalDuas);
    final prayer = _filter(context, _prayerDuas);
    final quran = _filter(context, _quranDuas);

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => AppSidePanel.open(context),
        ),
        title: Text(
          AppText.of(context, 'dua'),
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              _selectedVoice == AudioProfile.male ? Icons.male : Icons.female,
              color: scheme.primary,
            ),
            onSelected: (value) {
              if (value == 'female' && !AppPreferences.isPremiumEnabled()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppText.of(context, 'duaFemaleVoicePremiumSnack'),
                      style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                    ),
                    backgroundColor: const Color(0xFF7C3AED),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.all(16),
                    action: SnackBarAction(
                      label: AppText.of(context, 'premiumShort'),
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
                return;
              }
              setState(() => _selectedVoice = AudioProfile.fromValue(value));
              AppPreferences.box.put('dua_voice', value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'female',
                child: Row(
                  children: [
                    Icon(
                      Icons.female,
                      color: _selectedVoice == AudioProfile.female
                          ? scheme.primary
                          : scheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppText.of(context, 'femaleVoiceLabel'),
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: _selectedVoice == AudioProfile.female
                                  ? scheme.primary
                                  : scheme.onSurface,
                            ),
                          ),
                          Text(
                            'Sadece internet bağlantısı ile',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              color: Colors.grey,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded, size: 10, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 3),
                            Text(
                              AppText.of(context, 'premiumShort'),
                              style: const TextStyle(
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
              PopupMenuItem(
                value: 'male',
                child: Row(
                  children: [
                    Icon(
                      Icons.male,
                      color: _selectedVoice == AudioProfile.male
                          ? scheme.primary
                          : scheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppText.of(context, 'maleVoiceLabel'),
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: _selectedVoice == AudioProfile.male
                              ? scheme.primary
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? scheme.surfaceContainerHigh
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: scheme.onSurfaceVariant,
                        ),
                        hintText: AppText.of(context, 'duaSearchHint'),
                        hintStyle: TextStyle(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        _FilterTab(
                          label: AppText.of(context, 'generalDuas'),
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                        const SizedBox(width: 12),
                        _FilterTab(
                          label: AppText.of(context, 'prayerDuas'),
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                        const SizedBox(width: 12),
                        _FilterTab(
                          label: AppText.of(context, 'quranDuas'),
                          isSelected: _selectedTab == 2,
                          onTap: () => setState(() => _selectedTab = 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_selectedTab == 0)
            _buildDuaSliverList(general)
          else if (_selectedTab == 1)
            _buildDuaSliverList(prayer)
          else
            _buildDuaSliverList(quran),
        ],
      ),
    );
  }

  void _toggleFav(_DuaItem item) {
    setState(() {
      if (_favorites.contains(item.id)) {
        _favorites.remove(item.id);
      } else {
        _favorites.add(item.id);
      }
    });
    AppPreferences.box.put('favorite_dua_ids', _favorites.toList());
  }

  Widget _buildDuaSliverList(List<_DuaItem> items) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          final isFav = _favorites.contains(item.id);
          final isPlaying = _playingTitle == item.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerLow
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black26
                      : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                iconColor: Theme.of(context).colorScheme.primary,
                collapsedIconColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                title: Text(
                  AppText.of(context, item.titleKey),
                  style: TextStyle(
                    fontFamily: 'Noto Serif',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? const Color(0xFF064E3B)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                              : const Color(0xFFF5F3EF)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SelectableText(
                          item.arabic,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 26,
                            height: 1.8,
                            color: isPlaying
                                ? Colors.white
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFB0F0D6)
                                    : Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        if (isPlaying) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _ttsProgress,
                              minHeight: 3,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.graphic_eq, size: 12, color: Color(0xFFD97706)),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppText.of(context, 'duaPlayingLabel'),
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${(_ttsProgress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppText.of(context, 'duaReadLabel'),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.transliteration,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppText.of(context, 'duaMeaningLabel'),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppText.of(context, item.bodyKey),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      FloatingActionButton.small(
                        heroTag: null,
                        elevation: 0,
                        backgroundColor: isFav
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        foregroundColor: isFav
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF002117)
                                  : Colors.white)
                            : Theme.of(context).colorScheme.onSurface,
                        onPressed: () => _toggleFav(item),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isPlaying
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                            foregroundColor: isPlaying
                                ? Theme.of(context).colorScheme.onError
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => _speak(item),
                          icon: Icon(
                            isPlaying
                                ? Icons.stop_circle_rounded
                                : Icons.volume_up_rounded,
                          ),
                          label: Text(
                            isPlaying
                                ? AppText.of(context, 'duaStop')
                                : AppText.of(context, 'duaListen'),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (!AppPreferences.isPremiumEnabled()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppText.of(context, 'duaDownloadPremiumSnack'),
                                        style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF7C3AED),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                margin: const EdgeInsets.all(16),
                                action: SnackBarAction(
                                  label: AppText.of(context, 'premiumShort'),
                                  textColor: Colors.white,
                                  onPressed: () => context.go('/premium'),
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            size: 20,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }, childCount: items.length),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBg = isDark ? const Color(0xFF95D3BA) : const Color(0xFF003527);
    final activeFg = isDark ? const Color(0xFF003527) : Colors.white;

    final inactiveBg = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final inactiveFg = isDark
        ? const Color(0xFF95D3BA)
        : const Color(0xFF003527);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.bold,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}
