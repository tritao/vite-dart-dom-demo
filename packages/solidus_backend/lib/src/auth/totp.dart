import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

class Totp {
  Totp({
    this.periodSeconds = 30,
    this.digits = 6,
  });

  final int periodSeconds;
  final int digits;

  bool verifyCode({
    required Uint8List secret,
    required String code,
    required DateTime now,
    int window = 1,
  }) {
    final trimmed = code.trim();
    if (trimmed.length != digits || int.tryParse(trimmed) == null) return false;

    final step = now.millisecondsSinceEpoch ~/ (periodSeconds * 1000);
    for (var offset = -window; offset <= window; offset++) {
      final expected = generateCode(secret: secret, timeStep: step + offset);
      if (expected == trimmed) return true;
    }
    return false;
  }

  String generateCode({required Uint8List secret, required int timeStep}) {
    final msg = Uint8List(8);
    final data = ByteData.sublistView(msg);
    data.setInt64(0, timeStep, Endian.big);

    final mac = crypto.Hmac(crypto.sha1, secret).convert(msg).bytes;
    final offset = mac.last & 0x0f;
    final binary = ((mac[offset] & 0x7f) << 24) |
        ((mac[offset + 1] & 0xff) << 16) |
        ((mac[offset + 2] & 0xff) << 8) |
        (mac[offset + 3] & 0xff);
    final mod = pow(10, digits).toInt();
    final otp = binary % mod;
    return otp.toString().padLeft(digits, '0');
  }
}

class Base32 {
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static String encode(Uint8List bytes) {
    var buffer = 0;
    var bitsLeft = 0;
    final out = StringBuffer();

    for (final b in bytes) {
      buffer = (buffer << 8) | (b & 0xff);
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        final index = (buffer >> (bitsLeft - 5)) & 31;
        bitsLeft -= 5;
        out.write(_alphabet[index]);
      }
    }

    if (bitsLeft > 0) {
      final index = (buffer << (5 - bitsLeft)) & 31;
      out.write(_alphabet[index]);
    }

    return out.toString();
  }

  static Uint8List decode(String input) {
    final normalized = input
        .trim()
        .replaceAll('=', '')
        .replaceAll(' ', '')
        .toUpperCase();

    var buffer = 0;
    var bitsLeft = 0;
    final out = <int>[];

    for (var i = 0; i < normalized.length; i++) {
      final c = normalized[i];
      final idx = _alphabet.indexOf(c);
      if (idx == -1) {
        throw FormatException('Invalid base32 character: $c');
      }
      buffer = (buffer << 5) | idx;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        out.add((buffer >> (bitsLeft - 8)) & 0xff);
        bitsLeft -= 8;
      }
    }

    return Uint8List.fromList(out);
  }
}

