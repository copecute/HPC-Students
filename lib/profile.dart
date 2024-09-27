import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import 'cookie_provider.dart';
import 'config.dart';
import 'loginScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static String _hoTen = '';
  static String _dienThoai = '';
  static String _ngaySinh = '';
  static String _gioiTinh = 'Nam';
  static String _truongTHPT = '';
  static String _cmnd = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Kiểm tra nếu thông tin đã được tải trước đó
    if (_hoTen.isEmpty) {
      _fetchData(); // Nếu chưa có thông tin, tải dữ liệu
    } else {
      setState(() {
        _isLoading = false; // Nếu đã có thông tin, không cần tải lại
      });
    }
  }

  Future<void> _fetchData() async {
    // Lấy cookie từ CookieProvider
    String? cookie = Provider.of<CookieProvider>(context, listen: false).getCookie();

    // Nếu không có cookie, chuyển hướng về màn hình đăng nhập
    if (cookie == null || cookie.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()), // Chuyển hướng đến LoginScreen
      );
      return;
    }

    final url = '$baseUrl/SinhVien/ThongTinSinhVien';

    // Tạo HttpClient không kiểm tra SSL
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    // Tạo IOClient với HttpClient tùy chỉnh
    final ioClient = IOClient(httpClient);

    try {
      final response = await ioClient.get(
        Uri.parse(url),
        headers: {
          'Cookie': cookie, // Gửi cookie để xác thực
        },
      );

      if (response.statusCode == 200) {
        // Phân tích HTML
        var document = htmlParser.parse(response.body);

        // Lấy thông tin sinh viên từ các input
        _hoTen = document.getElementById("Ho_ten")?.attributes['value'] ?? '';
        _dienThoai = document.getElementById("Dienthoai_canhan")?.attributes['value'] ?? '';
        _ngaySinh = document.getElementById("Ngay_sinh")?.attributes['value'] ?? '';
        _gioiTinh = document.getElementById("ID_gioi_tinh")?.querySelector('option[selected]')?.text ?? 'Nam';
        _truongTHPT = document.getElementById("TruongTHPT")?.attributes['value'] ?? '';
        _cmnd = document.getElementById("CMND")?.attributes['value'] ?? '';

        setState(() {
          _isLoading = false; // Tắt trạng thái loading
        });
      } else {
        setState(() {
          _isLoading = false; // Tắt trạng thái loading
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Tắt trạng thái loading
      });
    } finally {
      ioClient.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông Tin Sinh Viên'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Hiển thị trạng thái loading
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Họ và Tên: $_hoTen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Điện thoại: $_dienThoai'),
              SizedBox(height: 8),
              Text('Ngày sinh: $_ngaySinh'),
              SizedBox(height: 8),
              Text('Giới tính: $_gioiTinh'),
              SizedBox(height: 8),
              Text('Trường THPT: $_truongTHPT'),
              SizedBox(height: 8),
              Text('CMND: $_cmnd'),
            ],
          ),
        ),
      ),
    );
  }
}
