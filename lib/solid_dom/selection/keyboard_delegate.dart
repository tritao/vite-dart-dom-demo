abstract interface class KeyboardDelegate {
  String? getFirstKey();
  String? getLastKey();
  String? getKeyBelow(String key);
  String? getKeyAbove(String key);
  String? getKeyPageBelow(String key);
  String? getKeyPageAbove(String key);
}

