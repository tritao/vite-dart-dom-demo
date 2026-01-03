import 'dart:html';

void main() {
  final app = document.querySelector('#app');
  if (app == null) return;

  app.text = 'Hello from Dart (compiled by Vite)!';
}

