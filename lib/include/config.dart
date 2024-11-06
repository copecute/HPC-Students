import 'dart:io';

// API Constants
const String baseUrl = 'https://sinhvien.bachkhoahanoi.edu.vn';
const String blogID = '8781675348507880774';
const String openWeatherMapApiKey = 'c1bc8c17d211d2549fe7a22e81e09267';

// Spreadsheet Configuration
const String SpreadApiKey =
    'MIiwxJTx8h3a3HLYvpYpWXsywFH71f5jYP1IQo8AMUwmZr9H7y';

class SpreadsheetAPI {
  static const Map<String, String> _ids = {
    'libraryBooks':
        'AKfycbyrp2Yzjg9x_Au40kW-g0OxzvSDX1wWPcHczmrjvMxnw4I1o5FO08HmP9bX4xpV2Xjj',
    'canteen':
        'AKfycbxQR7fXvo3xaJRoPj3EytGor6RGMYcOozeyFMR5nw0n2lxPRSbUNc40r4wJ1fyTTqoJ',
    'imgur':
        'AKfycbxF4jghNvVTfOtQZPUOhYbUd0dvNn5_qbWLyqkQoZgYh7djadadclPg4l5M5YPZpT2j',
    'vexe':
        'AKfycbzTP6lbps3TD1YbdHQBrhmGxCKJR_N685A1BL0Ht_Bd21GuqMv2TAkcxQWEzky6tWK_',
    'profiles':
        'AKfycbxE7TekaOTdNz30t1h_NarGXbEmBQVvYBH2qQ7RwGFaxvlGWZdYQmVGsYTvP8-ZhIOP',
    'studentmarket':
        'AKfycbwLJHekRHa-oE8eEGj0m6lhIENu6qDPPhK1FkAxjEQaKCZA9yaIR6FLHZwiwwX4r9cC'
  };

  static String id(String type) {
    final id = _ids[type];
    if (id == null) throw Exception('Invalid spreadsheet type: $type');
    return 'https://script.google.com/macros/s/$id/exec';
  }

  // Getters tiện lợi
  static String get libraryBooks => id('libraryBooks');
  static String get canteen => id('canteen');
  static String get imgur => id('imgur');
  static String get vexe => id('vexe');
  static String get profiles => id('profiles');
  static String get studentmarket => id('studentmarket');
}

// HTTP Configuration
void setupHttpOverrides() {
  HttpOverrides.global = MyHttpOverrides();
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
