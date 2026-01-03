@JS()
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('morphPatch')
external web.Element morphPatch(web.Element fromNode, web.Element toNode);
