import "package:web/web.dart" as web;

String _userAgentLower() {
  try {
    return ("${web.window.navigator.userAgent}").toLowerCase();
  } catch (_) {
    return "";
  }
}

bool _isMac() {
  try {
    final ua = _userAgentLower();
    return ua.contains("macintosh") || ua.contains("mac os");
  } catch (_) {
    return false;
  }
}

bool _isAppleDevice() {
  try {
    final ua = _userAgentLower();
    return ua.contains("iphone") ||
        ua.contains("ipad") ||
        ua.contains("ipod") ||
        ua.contains("macintosh") ||
        ua.contains("mac os");
  } catch (_) {
    return false;
  }
}

bool isNonContiguousSelectionModifier(Object e) {
  final altKey = switch (e) {
    web.KeyboardEvent ev => ev.altKey,
    web.MouseEvent ev => ev.altKey,
    web.PointerEvent ev => ev.altKey,
    _ => false,
  };
  final ctrlKey = switch (e) {
    web.KeyboardEvent ev => ev.ctrlKey,
    web.MouseEvent ev => ev.ctrlKey,
    web.PointerEvent ev => ev.ctrlKey,
    _ => false,
  };
  // On Apple devices, Ctrl+Arrow has a system-wide meaning; use Alt instead.
  return _isAppleDevice() ? altKey : ctrlKey;
}

bool isCtrlKeyPressed(Object e) {
  final ctrlKey = switch (e) {
    web.KeyboardEvent ev => ev.ctrlKey,
    web.MouseEvent ev => ev.ctrlKey,
    web.PointerEvent ev => ev.ctrlKey,
    _ => false,
  };
  final metaKey = switch (e) {
    web.KeyboardEvent ev => ev.metaKey,
    web.MouseEvent ev => ev.metaKey,
    web.PointerEvent ev => ev.metaKey,
    _ => false,
  };
  return _isMac() ? metaKey : ctrlKey;
}

void focusWithoutScrolling(web.HTMLElement el) {
  try {
    el.focus(web.FocusOptions(preventScroll: true));
  } catch (_) {
    try {
      el.focus();
    } catch (_) {}
  }
}

void scrollIntoViewWithin(web.HTMLElement container, web.HTMLElement el) {
  try {
    final cRect = container.getBoundingClientRect();
    final eRect = el.getBoundingClientRect();
    final viewTop = container.scrollTop;
    final viewBottom = viewTop + cRect.height;
    final elTop = (eRect.top - cRect.top) + viewTop;
    final elBottom = elTop + eRect.height;

    if (elTop < viewTop) {
      container.scrollTop = elTop;
    } else if (elBottom > viewBottom) {
      container.scrollTop = elBottom - cRect.height;
    }
  } catch (_) {
    try {
      el.scrollIntoView();
    } catch (_) {}
  }
}

String _stringForKey(String key) {
  // If key is length 1, it's a character; if it doesn't start with A-Z, it's a
  // Unicode character key name (per UI Events key values).
  if (key.length == 1) return key;
  final asciiName = RegExp(r"^[A-Z]", caseSensitive: false);
  if (!asciiName.hasMatch(key)) return key;
  return "";
}

bool isAllSameLetter(String search) {
  if (search.isEmpty) return false;
  final first = search[0];
  for (var i = 1; i < search.length; i++) {
    if (search[i] != first) return false;
  }
  return true;
}

String? typeaheadCharForKey(String key) {
  final c = _stringForKey(key);
  if (c.isEmpty) return null;
  return c;
}
