import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import '../include/cookie_provider.dart';
import '../include/config.dart';
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
    if (_hoTen.isEmpty) {
      _fetchData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchData() async {
    String? cookie = Provider.of<CookieProvider>(context, listen: false).getCookie();

    if (cookie == null || cookie.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      return;
    }

    final url = '$baseUrl/SinhVien/ThongTinSinhVien';
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    final ioClient = IOClient(httpClient);

    try {
      final response = await ioClient.get(
        Uri.parse(url),
        headers: {
          'Cookie': cookie,
        },
      );

      if (response.statusCode == 200) {
        var document = htmlParser.parse(response.body);

        _hoTen = document.getElementById("Ho_ten")?.attributes['value'] ?? '';
        _dienThoai = document.getElementById("Dienthoai_canhan")?.attributes['value'] ?? '';
        _ngaySinh = document.getElementById("Ngay_sinh")?.attributes['value'] ?? '';
        _gioiTinh = document.getElementById("ID_gioi_tinh")?.querySelector('option[selected]')?.text ?? 'Nam';
        _truongTHPT = document.getElementById("TruongTHPT")?.attributes['value'] ?? '';
        _cmnd = document.getElementById("CMND")?.attributes['value'] ?? '';

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
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
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50, // Kích thước avatar
                  backgroundImage: AssetImage('assets/avatar.png'), // Ảnh avatar
                ),
              ),
              SizedBox(height: 16),
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
