final class AppConfig {
  const AppConfig({
    required this.usersAll,
    required this.usersLimited,
  });

  static const contextKey = 'config';

  final String usersAll;
  final String usersLimited;
}
