import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

String base64UrlNoPad(List<int> bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}

Uint8List randomBytes(int length) {
  final rand = Random.secure();
  return Uint8List.fromList(List<int>.generate(length, (_) => rand.nextInt(256)));
}

String hmacSha256Base64UrlNoPad({
  required List<int> key,
  required List<int> message,
}) {
  final mac = crypto.Hmac(crypto.sha256, key).convert(message).bytes;
  return base64UrlNoPad(mac);
}

class AesGcmEncryptor {
  AesGcmEncryptor(this._keyBytes);

  final List<int> _keyBytes;
  final _algo = AesGcm.with256bits();

  Future<({Uint8List nonce, Uint8List ciphertext})> encrypt(Uint8List plaintext) async {
    final nonce = randomBytes(12);
    final secretKey = SecretKeyData(_keyBytes);
    final box = await _algo.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
    final combined = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
    return (nonce: nonce, ciphertext: combined);
  }

  Future<Uint8List> decrypt({
    required Uint8List nonce,
    required Uint8List ciphertext,
  }) async {
    if (ciphertext.length < 16) {
      throw StateError('ciphertext too short');
    }
    final secretKey = SecretKeyData(_keyBytes);
    final macBytes = ciphertext.sublist(ciphertext.length - 16);
    final ct = ciphertext.sublist(0, ciphertext.length - 16);
    final box = SecretBox(ct, nonce: nonce, mac: Mac(macBytes));
    return Uint8List.fromList(
      await _algo.decrypt(box, secretKey: secretKey),
    );
  }
}

