import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:hpc_students/include/config.dart';

Future<void> saveAvatarToAPI(String? avatarUrl, String maSinhVien) async {
  if (avatarUrl == null || avatarUrl.isEmpty) {
    print("URL avatar là null hoặc trống, không cập nhật API.");
    return;
  }

  final url = Uri.parse('${SpreadsheetAPI.profiles}');

  final Map<String, String> body = {
    'copecute': SpreadApiKey,
    'action': 'updateProfile',
    'mssv': maSinhVien,
    'avatar': avatarUrl,
    'avatartimestamp': DateTime.now().toIso8601String(),
  };

  try {
    var response = await http.post(
      url,
      body: body,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    // Xử lý chuyển hướng thủ công
    int maxRedirects = 5;
    int redirectCount = 0;

    while ((response.statusCode == 301 || response.statusCode == 302) &&
        redirectCount < maxRedirects) {
      String? location = response.headers['location'];
      if (location != null) {
        print("40. Theo dõi chuyển hướng đến: $location");
        response = await http.get(Uri.parse(location));
        redirectCount++;
      } else {
        break;
      }
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        print(
            "Cập nhật thành công avatar và timestamp cho $maSinhVien: $avatarUrl");
      } else {
        print("Không thể cập nhật avatar: ${data['error']}");
      }
    } else {
      print("Không thể cập nhật avatar: ${response.statusCode}");
      print("Nội dung phản hồi: ${response.body}");
    }
  } catch (e) {
    print('Lỗi khi lưu avatar vào API: $e');
  }
}

Future<String?> getAvatarFromAPI(String maSinhVien) async {
  final url = Uri.parse('${SpreadsheetAPI.profiles}');

  final Map<String, String> body = {
    'copecute': SpreadApiKey,
    'action': 'getProfile',
    'mssv': maSinhVien,
    'fields': 'Avatar,AvatarTimestamp',
  };

  try {
    var response = await http.post(
      url,
      body: body,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    // Xử lý chuyển hướng thủ công
    int maxRedirects = 5;
    int redirectCount = 0;

    while ((response.statusCode == 301 || response.statusCode == 302) &&
        redirectCount < maxRedirects) {
      String? location = response.headers['location'];
      if (location != null) {
        print("92. Theo dõi chuyển hướng đến: $location");
        response = await http.get(Uri.parse(location));
        redirectCount++;
      } else {
        break;
      }
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String? avatarUrl = data['Avatar'];
      String? timestampStr = data['AvatarTimestamp'];

      if (avatarUrl != null && timestampStr != null) {
        // Phân tích timestamp
        DateTime timestamp = DateTime.parse(timestampStr);
        DateTime now = DateTime.now();
        Duration difference = now.difference(timestamp);

        print("Timestamp avatar: $timestamp");
        print("Thời gian hiện tại: $now");
        print("Số giờ chênh lệch: ${difference.inHours}");

        // Nếu avatar đã cũ hơn 10 giờ, hãy lấy một avatar mới
        if (difference.inHours >= 10) {
          print("Avatar đã cũ hơn 10 giờ, đang lấy một avatar mới...");
          return null; // Điều này sẽ kích hoạt fetchAvatarFromZalo trong checkAvatarFromAPI
        }
        return avatarUrl;
      }
    } else {
      print("Không thể lấy avatar: ${response.statusCode}");
      print("Nội dung phản hồi: ${response.body}");
    }
  } catch (e) {
    print('Lỗi khi lấy avatar từ API: $e');
  }
  return null;
}

Future<String?> fetchAvatarFromZalo(String dienThoai) async {
  final url = 'https://zalo.me/$dienThoai';
  print(url);
  try {
    var response = await http.get(Uri.parse(url));

    // Xử lý chuyển hướng thủ công
    int maxRedirects = 5;
    int redirectCount = 0;

    while ((response.statusCode == 301 || response.statusCode == 302) &&
        redirectCount < maxRedirects) {
      String? location = response.headers['location'];
      if (location != null) {
        print("zl Theo dõi chuyển hướng đến: $location");
        response = await http.get(Uri.parse(location));
        redirectCount++;
      } else {
        break;
      }
    }

    if (response.statusCode == 200) {
      RegExp regExp = RegExp(r'"avatar":"(.*?)"');
      Match? match = regExp.firstMatch(response.body);
      return match?.group(1);
    }
  } catch (e) {
    print('Lỗi khi lấy avatar từ Zalo: $e');
  }
  return null;
}

// Hàm trợ giúp để tạo IOClient với xử lý chứng chỉ SSL
Future<IOClient> _getIOClient() async {
  HttpClient httpClient = HttpClient()
    ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);

  return IOClient(httpClient);
}
