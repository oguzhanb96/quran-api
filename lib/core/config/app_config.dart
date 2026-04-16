// ignore_for_file: avoid_classes_with_only_static_members

class AppConfig {
  static const String _d0 = String.fromEnvironment(
    'VPS_BASE_URL',
    defaultValue: '',
  );

  static const String _d1 = String.fromEnvironment(
    'QURAN_API_BASE',
    defaultValue: '',
  );

  static const String _d2 = String.fromEnvironment(
    'PRAYER_API_BASE',
    defaultValue: '',
  );

  static const String _d3 = String.fromEnvironment(
    'GEOCODING_API_BASE',
    defaultValue: '',
  );

  static const String _d4 = String.fromEnvironment(
    'NOMINATIM_BASE',
    defaultValue: '',
  );

  static String get vpsBaseUrl =>
      _d0.isNotEmpty ? _d0 : _fb('aHR0cDovL3J1ZGRkNDBuMmhzdDh5cjdyYTBycDMzOS4xOTIuMjI3LjIxOS4yMzAuc3NsaXAuaW8=');

  static String get quranApiBase =>
      _d1.isNotEmpty ? _d1 : _fb('aHR0cHM6Ly9hcGkuYWxxdXJhbi5jbG91ZC92MQ==');

  static String get prayerApiBase =>
      _d2.isNotEmpty ? _d2 : _fb('aHR0cHM6Ly9hcGkuYWxhZGhhbi5jb20vdjE=');

  static String get geocodingApiBase =>
      _d3.isNotEmpty ? _d3 : _fb('aHR0cHM6Ly9nZW9jb2RpbmctYXBpLm9wZW4tbWV0ZW8uY29tL3YxL3NlYXJjaA==');

  static String get nominatimBase =>
      _d4.isNotEmpty ? _d4 : _fb('aHR0cHM6Ly9ub21pbmF0aW0ub3BlbnN0cmVldG1hcC5vcmcvc2VhcmNo');

  static const String _d5 = String.fromEnvironment('SUPABASE_URL');
  static const String _d6 = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl => _d5;
  static String get supabaseAnonKey => _d6;

  static String _fb(String b64) {
    final bytes = _b64Decode(b64);
    return String.fromCharCodes(bytes);
  }

  static List<int> _b64Decode(String s) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
    final out = <int>[];
    var i = 0;
    while (i < s.length) {
      final c0 = chars.indexOf(s[i++]);
      final c1 = chars.indexOf(s[i++]);
      final c2 = chars.indexOf(s[i++]);
      final c3 = chars.indexOf(s[i++]);
      out.add((c0 << 2) | (c1 >> 4));
      if (c2 != 64) out.add(((c1 & 0xF) << 4) | (c2 >> 2));
      if (c3 != 64) out.add(((c2 & 0x3) << 6) | c3);
    }
    return out;
  }
}
