import 'package:logging/logging.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

class OutboundEmail {
  OutboundEmail({
    required this.to,
    required this.from,
    required this.subject,
    required this.text,
    this.html,
  });

  final String to;
  final String from;
  final String subject;
  final String text;
  final String? html;
}

abstract class EmailSender {
  Future<void> send(OutboundEmail email);
}

class LogEmailSender implements EmailSender {
  LogEmailSender(this._logger);

  final Logger _logger;

  @override
  Future<void> send(OutboundEmail email) async {
    _logger.info(
      'email(to=${email.to}, subject=${email.subject})\n${email.text}',
    );
  }
}

class SmtpEmailSender implements EmailSender {
  SmtpEmailSender({
    required String host,
    required int port,
    required bool ssl,
    required bool allowInsecure,
    String? username,
    String? password,
  }) : _server = SmtpServer(
          host,
          port: port,
          ssl: ssl,
          allowInsecure: allowInsecure,
          username: username,
          password: password,
        );

  final SmtpServer _server;

  @override
  Future<void> send(OutboundEmail email) async {
    final msg = mailer.Message()
      ..from = mailer.Address(email.from)
      ..recipients.add(email.to)
      ..subject = email.subject
      ..text = email.text;
    if (email.html != null) msg.html = email.html!;
    await mailer.send(msg, _server);
  }
}
