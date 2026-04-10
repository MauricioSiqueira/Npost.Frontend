// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

class WebSessionStorage {
  const WebSessionStorage();

  String? read(String key) {
    return html.window.sessionStorage[key];
  }

  void write(String key, String value) {
    html.window.sessionStorage[key] = value;
  }

  void delete(String key) {
    html.window.sessionStorage.remove(key);
  }
}
