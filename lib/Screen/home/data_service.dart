import 'dart:convert';
import 'dart:io';
import 'package:hpc_students/include/config.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'firebase_service.dart'; // Import the new Firebase service

class DataService {
  final FirebaseService firebaseService =
      FirebaseService(); // Initialize FirebaseService

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

  Future<void> saveOrUpdateToFirestore(String maSinhVien, String hoTen,
      String trangThai, String tbcTichLuy) async {
    await firebaseService.saveOrUpdateStudent(
        maSinhVien, hoTen, trangThai, tbcTichLuy);
  }
}
