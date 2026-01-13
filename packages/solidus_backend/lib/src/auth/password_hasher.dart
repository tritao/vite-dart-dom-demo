import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class PasswordHasher {
  PasswordHasher({
    required this.iterations,
    required this.bits,
  });

  final int iterations;
  final int bits;

  static final _rand = Random.secure();

  Future<String> hash(String password) async {
    final salt = List<int>.generate(16, (_) => _rand.nextInt(256));
    final derived = await _derive(password, salt);
    return [
      'pbkdf2_sha256',
      iterations.toString(),
      base64UrlEncode(salt),
      base64UrlEncode(derived),
    ].join(r'$');
  }

  Future<bool> verify(String password, String encoded) async {
    final parts = encoded.split(r'$');
    if (parts.length != 4) return false;
    if (parts[0] != 'pbkdf2_sha256') return false;
    final iters = int.tryParse(parts[1]);
    if (iters == null || iters <= 0) return false;
    final salt = base64Url.decode(parts[2]);
    final expected = base64Url.decode(parts[3]);
    final derived = await _derive(password, salt, iterationsOverride: iters);
    return _constantTimeEquals(derived, expected);
  }

  Future<List<int>> _derive(
    String password,
    List<int> salt, {
    int? iterationsOverride,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterationsOverride ?? iterations,
      bits: bits,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKeyData(utf8.encode(password)),
      nonce: salt,
    );
    return (await key.extractBytes());
  }
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= (a[i] ^ b[i]);
  }
  return diff == 0;
}
