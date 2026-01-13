import 'dart:convert';
import 'dart:typed_data';

import 'package:solidus_backend/src/auth/totp.dart';
import 'package:test/test.dart';

void main() {
  test('Base32 roundtrip', () {
    final bytes = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final encoded = Base32.encode(bytes);
    final decoded = Base32.decode(encoded);
    expect(decoded, bytes);
  });

  test('TOTP RFC6238 SHA1 vector (digits=8)', () {
    // Secret is "12345678901234567890" as ASCII, per RFC 6238.
    final secret = Uint8List.fromList(utf8.encode('12345678901234567890'));
    final totp = Totp(digits: 8, periodSeconds: 30);

    // For Unix time 59s, timeStep = floor(59/30) = 1. Expected 94287082.
    final code = totp.generateCode(secret: secret, timeStep: 1);
    expect(code, '94287082');
  });
}

