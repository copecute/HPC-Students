import 'dart:io';
import 'package:hpc_students/include/config.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;

class DataService {
  final String baseScriptUrl =
      'https://script.google.com/macros/s/AKfycbxE7TekaOTdNz30t1h_NarGXbEmBQVvYBH2qQ7RwGFaxvlGWZdYQmVGsYTvP8-ZhIOP/exec';
  final String copecute = 'MIiwxJTx8h3a3HLYvpYpWXsywFH71f5jYP1IQo8AMUwmZr9H7y';

  Future<void> fetchData(String cookie, Function(Map<String, String>) onSuccess,
      Function(String) onError) async {
    final url = '$baseUrl/TraCuuDiem/Index';
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    try {
      final response =
          await http.get(Uri.parse(url), headers: {'Cookie': cookie});
      if (response.statusCode == 200) {
        var document = htmlParser.parse(response.body);
        Map<String, String> data = {
          'maSinhVien': document.getElementById("MaSinhVien")?.text.trim() ??
              'Không tìm thấy mã sinh viên',
          'hoTen': document
                  .querySelector("a.dropdown .styMenu")
                  ?.innerHtml
                  .trim()
                  .split('<br>')[0] ??
              'Không tìm thấy tên',
          'trangThai': document
                  .querySelector("a.dropdown .styMenu")
                  ?.innerHtml
                  .trim()
                  .split('<br>')[1] ??
              'Không tìm thấy trạng thái',
          'tinChiTichLuy':
              document.getElementById("TinChiTichLuy")?.text.trim() ??
                  'Không tìm thấy tín chỉ',
          'tbcTichLuy': document.getElementById("TBCTichLuyH10")?.text.trim() ??
              'Không tìm thấy TBC tích luỹ',
          'xepLoaiHT': document.getElementById("XepLoaiHTH10")?.text.trim() ??
              'Không tìm thấy xếp loại học tập',
        };
        onSuccess(data);
      } else {
        onError('Không có kết nối internet. Vui lòng kiểm tra lại.');
      }
    } on SocketException catch (_) {
      onError('Không có kết nối internet. Vui lòng kiểm tra lại.');
    } catch (e) {
      onError('Không có kết nối internet. Vui lòng kiểm tra lại.');
    }
  }

  Future<void> saveOrUpdateToSheet(String maSinhVien, String hoTen,
      String trangThai, String tbcTichLuy, String tinChiTichLuy) async {
    try {
      var client = http.Client();
      try {
        var response = await client.post(
          Uri.parse(baseScriptUrl),
          body: {
            'copecute': copecute,
            'action': 'updateProfile',
            'mssv': maSinhVien,
            'fullName': hoTen,
            'tbc': tbcTichLuy,
            'tinChiTichLuy': tinChiTichLuy,
            'tbctimestamp': DateTime.now().toIso8601String(),
          },
          headers: {
            'Accept': '*/*',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        );

        if (response.statusCode == 302 || response.statusCode == 303) {
          String? redirectUrl = response.headers['location'];
          if (redirectUrl != null) {
            response = await client.get(Uri.parse(redirectUrl));
          }
        }

        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Cập nhật dữ liệu lên Google Sheet thành công');
        } else {
          print('Lỗi khi cập nhật dữ liệu: ${response.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('Lỗi khi gửi request: $e');
    }
  }
}
