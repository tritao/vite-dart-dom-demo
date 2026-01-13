class EmailTemplates {
  static ({String subject, String text, String html}) passwordReset({
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
    final html = '''
<p>We received a request to reset your <strong>${_escape(appName)}</strong> password.</p>
<p><a href="${_escape(resetUrl)}">Reset your password</a> (expires in ${_escape(_formatDuration(expiresIn))}).</p>
<p>If you didn’t request this, you can ignore this email.</p>
''';
    return (subject: subject, text: text, html: html);
  }

  static ({String subject, String text, String html}) emailVerification({
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
    final html = '''
<p>Verify your email for <strong>${_escape(appName)}</strong> (expires in ${_escape(_formatDuration(expiresIn))}).</p>
<p><a href="${_escape(verifyUrl)}">Verify email</a></p>
<p>If you didn’t request this, you can ignore this email.</p>
''';
    return (subject: subject, text: text, html: html);
  }

  static String _formatDuration(Duration d) {
    if (d.inHours >= 24) return '${d.inDays} day(s)';
    if (d.inMinutes >= 60) return '${d.inHours} hour(s)';
    return '${d.inMinutes} minute(s)';
  }

  static String _escape(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
