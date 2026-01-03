final class User {
  User({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  static User fromJson(Map<String, Object?> json) => User(
        name: (json['name'] as String?) ?? '(no name)',
        email: (json['email'] as String?) ?? '',
      );
}
