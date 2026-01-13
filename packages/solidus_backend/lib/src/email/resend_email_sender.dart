import 'dart:convert';
import 'dart:io';

import 'email_sender.dart';

class ResendEmailSender extends EmailSender {
  ResendEmailSender({
    required String apiKey,
    Uri? endpoint,
  })  : _apiKey = apiKey,
        _endpoint = endpoint ?? Uri.parse('https://api.resend.com/emails'),
        _http = HttpClient();

  final String _apiKey;
  final Uri _endpoint;
  final HttpClient _http;

  @override
  Future<void> send(OutboundEmail email) async {
    final req = await _http.postUrl(_endpoint);
    req.headers.contentType = ContentType.json;
    req.headers.set('authorization', 'Bearer $_apiKey');
    req.headers.set('user-agent', 'solidus_backend');

    final payload = <String, Object?>{
      'from': email.from,
      'to': [email.to],
      'subject': email.subject,
      'text': email.text,
      if (email.html != null) 'html': email.html,
    };

    req.write(jsonEncode(payload));
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw StateError('Resend failed (${resp.statusCode}): $body');
    }
  }

  @override
  Future<void> close() async {
    _http.close(force: true);
  }
}
