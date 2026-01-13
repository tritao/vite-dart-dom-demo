import 'dart:io';

import 'package:shelf/shelf.dart';

String? remoteIp(Request request) {
  final conn = request.context['shelf.io.connection_info'];
  if (conn is HttpConnectionInfo) {
    return conn.remoteAddress.address;
  }
  return null;
}

