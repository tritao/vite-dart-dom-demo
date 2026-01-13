import 'package:solidus_backend/src/auth/password_hasher.dart';
import 'package:test/test.dart';

void main() {
  test('hash + verify', () async {
    final hasher = PasswordHasher(iterations: 5000, bits: 256);
    final hash = await hasher.hash('correct horse battery staple');
    expect(await hasher.verify('correct horse battery staple', hash), true);
    expect(await hasher.verify('wrong', hash), false);
  });
}

