import 'dart:io';

const String baseUrl = 'https://sinhvien.bachkhoahanoi.edu.vn';
const String blogID = '8781675348507880774';
const String ggsapiKey = 'MIiwxJTx8h3a3HLYvpYpWXsywFH71f5jYP1IQo8AMUwmZr9H7y';

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
