import 'dart:typed_data';

import 'package:solidus_backend/src/auth/totp.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    throw StateError('usage: dart run tool/gen_totp.dart <base32-secret> [timeSeconds]');
  }
  final secretB32 = args[0];
  final nowSeconds = args.length >= 2 ? int.parse(args[1]) : DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

  final secret = Base32.decode(secretB32);
  final totp = Totp(periodSeconds: 30, digits: 6);
  final timeStep = nowSeconds ~/ 30;
  final code = totp.generateCode(secret: Uint8List.fromList(secret), timeStep: timeStep);
  // ignore: avoid_print
  print(code);
}

