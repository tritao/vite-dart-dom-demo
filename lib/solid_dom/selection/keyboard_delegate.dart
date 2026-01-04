abstract class KeyboardDelegate {
  String? getKeyBelow(String key) => null;
  String? getKeyAbove(String key) => null;
  String? getKeyLeftOf(String key) => null;
  String? getKeyRightOf(String key) => null;
  String? getKeyPageBelow(String key) => null;
  String? getKeyPageAbove(String key) => null;

  String? getFirstKey([String? key, bool global = false]) => null;
  String? getLastKey([String? key, bool global = false]) => null;

  String? getKeyForSearch(String search, [String? fromKey]) => null;
}
