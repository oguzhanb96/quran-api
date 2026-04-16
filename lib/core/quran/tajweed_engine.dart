import 'package:flutter/material.dart' show Color;

/// Tajweed (Tecvid) renklendirme motoru.
///
/// Her kelimeyi analiz ederek hangi tecvid kuralının uygulandığını döndürür.
/// Renk standartları Quran Foundation / Tajweed Quran geleneğine dayanır.

enum TajweedRule {
  /// Gunneli nun/mim şeddesi — yeşil
  ghunna,

  /// İzhâr-ı Halk — açık okunuş (ء ه ع ح غ خ) — açık mavi
  izhar,

  /// İdğam (gunnesiz) — turuncu
  idghamNoGhunna,

  /// İdğam (gunneli) — açık yeşil
  idghamGhunna,

  /// İhfâ — saklanma — sarı
  ikhfa,

  /// İklâb — nun→mim dönüşümü — mor
  iqlab,

  /// Kalkale harfleri (ق ط ب ج د) — kırmızı
  qalqala,

  /// Med harfleri (uzatma) — mavi
  madd,

  /// Lam Şemsiyye — koyu sarı
  lamShamsi,

  /// Lam Kameriyye — soluk mavi
  lamQamari,

  /// Normal — varsayılan renk
  none,
}

class TajweedSpan {
  const TajweedSpan({required this.text, required this.rule});
  final String text;
  final TajweedRule rule;
}

class TajweedEngine {
  TajweedEngine._();

  // ── Harf grupları ────────────────────────────────────────────────────────

  static const _halqLetters = 'ءهعحغخ';
  static const _idghamGhunnaLetters = 'ينمو';
  static const _idghamNoGhunnaLetters = 'لر';
  static const _ikhfaLetters = 'صذثكجشقسدطزفتضظ';
  static const _qalqalaLetters = 'قطبجد';
  static const _maddLetters = 'اويىٰ';
  static const _shamsiLetters = 'تثدذرزسشصضطظلن';
  static const _harekes = 'َُِّْٰ';

  // ── Regex ────────────────────────────────────────────────────────────────

  static final _ghunnaRe = RegExp(r'[نم]ّ');

  // ── Ana analiz fonksiyonu ────────────────────────────────────────────────

  /// Bir ayetin tüm kelimelerini analiz eder, her kelime için [TajweedSpan] döner.
  static List<TajweedSpan> analyze(String ayahText) {
    final words = ayahText.split(' ').where((w) => w.isNotEmpty).toList();
    final spans = <TajweedSpan>[];
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final nextWord = i + 1 < words.length ? words[i + 1] : null;
      spans.add(TajweedSpan(text: word, rule: _classifyWord(word, nextWord)));
    }
    return spans;
  }

  static TajweedRule _classifyWord(String word, String? nextWord) {
    // Gunneli şedde
    if (_ghunnaRe.hasMatch(word)) return TajweedRule.ghunna;

    // Nun sakin veya tenvin
    final hasNunSakin = word.contains('نْ') ||
        word.contains('ً') ||
        word.contains('ٍ') ||
        word.contains('ٌ');

    if (hasNunSakin && nextWord != null && nextWord.isNotEmpty) {
      final next = _firstConsonant(nextWord);
      if (next != null) {
        // İklâb
        if (next == 'ب') return TajweedRule.iqlab;
        if (_halqLetters.contains(next)) return TajweedRule.izhar;
        if (_idghamGhunnaLetters.contains(next)) {
          return TajweedRule.idghamGhunna;
        }
        if (_idghamNoGhunnaLetters.contains(next)) {
          return TajweedRule.idghamNoGhunna;
        }
        if (_ikhfaLetters.contains(next)) return TajweedRule.ikhfa;
      }
    }

    // Lam tarif
    if (_startsWithLamTarif(word)) {
      final afterLam = _getLetterAfterLam(word);
      if (afterLam != null) {
        return _shamsiLetters.contains(afterLam)
            ? TajweedRule.lamShamsi
            : TajweedRule.lamQamari;
      }
    }

    // Kalkale
    if (_hasQalqala(word)) return TajweedRule.qalqala;

    // Med
    if (_hasMadd(word)) return TajweedRule.madd;

    return TajweedRule.none;
  }

  static bool _startsWithLamTarif(String word) {
    const prefixes = ['ال', 'وَال', 'فَال', 'بِال', 'كَال', 'لِل'];
    return prefixes.any((p) => word.startsWith(p));
  }

  static String? _firstConsonant(String word) {
    for (final ch in word.split('')) {
      if (!_harekes.contains(ch) && ch != ' ') return ch;
    }
    return null;
  }

  static String? _getLetterAfterLam(String word) {
    final lamIdx = word.indexOf('ال');
    if (lamIdx == -1) return null;
    var idx = lamIdx + 2;
    while (idx < word.length && _harekes.contains(word[idx])) {
      idx++;
    }
    if (idx >= word.length) return null;
    return word[idx];
  }

  static bool _hasQalqala(String word) {
    for (var i = 0; i < word.length; i++) {
      if (!_qalqalaLetters.contains(word[i])) continue;
      // Sukun sonrası veya kelime sonu
      if (i + 1 < word.length && word[i + 1] == 'ْ') return true;
      if (i == word.length - 1) return true;
    }
    return false;
  }

  static bool _hasMadd(String word) {
    for (var i = 0; i < word.length - 1; i++) {
      if (!_maddLetters.contains(word[i])) continue;
      final next = word[i + 1];
      if (next == 'ْ' || next == 'ء' || next == 'ٓ') return true;
      if (_maddLetters.contains(next)) return true;
    }
    // Uzatma işareti (madde)
    if (word.contains('ٓ') || word.contains('ٰ')) return true;
    return false;
  }
}

/// Tecvid kurallarının renk ve etiket eşlemesi.
extension TajweedRuleExt on TajweedRule {
  Color get ruleColor {
    switch (this) {
      case TajweedRule.ghunna:
        return const Color(0xFF10B981);
      case TajweedRule.izhar:
        return const Color(0xFF60A5FA);
      case TajweedRule.idghamGhunna:
        return const Color(0xFF34D399);
      case TajweedRule.idghamNoGhunna:
        return const Color(0xFFF97316);
      case TajweedRule.ikhfa:
        return const Color(0xFFFBBF24);
      case TajweedRule.iqlab:
        return const Color(0xFFA78BFA);
      case TajweedRule.qalqala:
        return const Color(0xFFEF4444);
      case TajweedRule.madd:
        return const Color(0xFF93C5FD);
      case TajweedRule.lamShamsi:
        return const Color(0xFFD97706);
      case TajweedRule.lamQamari:
        return const Color(0xFFBAE6FD);
      case TajweedRule.none:
        return const Color(0xFFFFFFFF);
    }
  }

  String get ruleLabel {
    switch (this) {
      case TajweedRule.ghunna:
        return 'Gunne';
      case TajweedRule.izhar:
        return 'İzhâr';
      case TajweedRule.idghamGhunna:
        return 'İdğam (Gunneli)';
      case TajweedRule.idghamNoGhunna:
        return 'İdğam (Gunnesiz)';
      case TajweedRule.ikhfa:
        return 'İhfâ';
      case TajweedRule.iqlab:
        return 'İklâb';
      case TajweedRule.qalqala:
        return 'Kalkale';
      case TajweedRule.madd:
        return 'Med';
      case TajweedRule.lamShamsi:
        return 'Lam Şemsiyye';
      case TajweedRule.lamQamari:
        return 'Lam Kameriyye';
      case TajweedRule.none:
        return '';
    }
  }
}
