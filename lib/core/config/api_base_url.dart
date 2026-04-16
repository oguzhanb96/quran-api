/// Normalizes API root URLs for Dio (no trailing slash).
class ApiBaseUrl {
  ApiBaseUrl._();

  static String normalize(String url) {
    var s = url.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}
