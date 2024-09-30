import 'package:flutter/material.dart';

class CookieProvider with ChangeNotifier {
  String? _cookie;

  String? getCookie() => _cookie;

  void setCookie(String cookie) {
    _cookie = cookie;
    notifyListeners();
  }
}
