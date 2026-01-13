import 'dart:io';

import 'package:solidus_backend/solidus_backend.dart';

Future<void> main(List<String> args) async {
  final config = SolidusBackendConfig.fromEnv();
  final server = await SolidusBackendServer.start(config);
  stdout.writeln('listening on http://${server.host}:${server.port}');
}

