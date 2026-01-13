import 'dart:async';

import 'package:logging/logging.dart';

import 'email_sender.dart';

class EmailDispatcher {
  EmailDispatcher({
    required EmailSender sender,
    required Logger logger,
  })  : _sender = sender,
        _logger = logger,
        _controller = StreamController<OutboundEmail>() {
    _worker = _run();
  }

  final EmailSender _sender;
  final Logger _logger;
  final StreamController<OutboundEmail> _controller;
  late final Future<void> _worker;

  void enqueue(OutboundEmail email) {
    if (_controller.isClosed) return;
    _controller.add(email);
  }

  Future<void> sendNow(OutboundEmail email) async {
    await _sender.send(email);
  }

  Future<void> close() async {
    await _controller.close();
    await _worker;
    await _sender.close();
  }

  Future<void> _run() async {
    await for (final email in _controller.stream) {
      try {
        await _sender.send(email);
      } catch (e, st) {
        _logger.warning('email delivery failed: $e\n$st');
      }
    }
  }
}
