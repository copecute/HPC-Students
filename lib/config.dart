import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hpc_students/traCuuLichHocScreen.dart';

const String baseUrl = 'https://sinhvien.bachkhoahanoi.edu.vn';

// Gọi hàm này trong hàm main của ứng dụng trước khi thực hiện bất kỳ yêu cầu nào
void setupHttpOverrides() {
  HttpOverrides.global = MyHttpOverrides();
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              true; // Bypass SSL verification
  }
}
