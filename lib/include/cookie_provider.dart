import 'package:flutter/material.dart';

class CookieProvider with ChangeNotifier {
  String? _cookie;

  // Getter for cookie
  String? get cookie => _cookie; // Added getter for cookie

  // Hàm để lấy cookie
  String? getCookie() {
    return _cookie;
  }

  // Hàm để cập nhật cookie
  void setCookie(String cookie) {
    _cookie = cookie;
    notifyListeners(); // Thông báo cho các widget đang lắng nghe về sự thay đổi
  }
}
