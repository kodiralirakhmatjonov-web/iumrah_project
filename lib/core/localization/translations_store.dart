class TranslationsStore {
  static Map<String, String> _data = {};
  static bool isReady = false;

  static void setAll(Map<String, String> map) {
    _data = map;
    isReady = true;
  }

  static String get(String key) {
    return _data[key] ?? '[$key]';
  }

  static void clear() {
    _data = {};
    isReady = false;
  }
}
