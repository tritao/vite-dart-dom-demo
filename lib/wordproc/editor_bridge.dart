@JS()
library dart_web_test.wordproc.editor_bridge;

import "dart:js_interop";

import "package:web/web.dart" as web;

@JS("wordprocEditorInit")
external void wordprocEditorInit(web.Element mount, String? initialJson);

@JS("wordprocEditorDestroy")
external void wordprocEditorDestroy(web.Element mount);

@JS("wordprocEditorSetDoc")
external void wordprocEditorSetDoc(web.Element mount, String? json);

@JS("wordprocEditorGetDoc")
external String? wordprocEditorGetDoc(web.Element mount);
