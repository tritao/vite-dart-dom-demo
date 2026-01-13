class EmailTemplates {
  static ({String subject, String text}) passwordReset({
    required String appName,
    required String resetUrl,
    required Duration expiresIn,
  }) {
    final subject = 'Reset your $appName password';
    final text = '''
We received a request to reset your $appName password.

Reset link (expires in ${_formatDuration(expiresIn)}):
$resetUrl

If you didn’t request this, you can ignore this email.
''';
    return (subject: subject, text: text);
  }

  static ({String subject, String text}) emailVerification({
    required String appName,
    required String verifyUrl,
    required Duration expiresIn,
  }) {
    final subject = 'Verify your $appName email';
    final text = '''
Verify your email for $appName (expires in ${_formatDuration(expiresIn)}):
$verifyUrl

If you didn’t request this, you can ignore this email.
''';
    return (subject: subject, text: text);
  }

  static String _formatDuration(Duration d) {
    if (d.inHours >= 24) return '${d.inDays} day(s)';
    if (d.inMinutes >= 60) return '${d.inHours} hour(s)';
    return '${d.inMinutes} minute(s)';
  }
}

