import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import 'cookie_provider.dart';
import 'config.dart';
import 'loginScreen.dart';

class TraCuuDiemRenLuyenScreen extends StatefulWidget {
  @override
  _TraCuuDiemRenLuyenScreenState createState() =>
      _TraCuuDiemRenLuyenScreenState();
}

class _TraCuuDiemRenLuyenScreenState extends State<TraCuuDiemRenLuyenScreen> {
  List<Map<String, String>> _cardData = [];
  bool _isLoading = true;
  bool _isFetched = false; // Biến kiểm tra dữ liệu đã được tải hay chưa

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Nếu dữ liệu đã được tải, không tải lại
    if (_isFetched) return;

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

    final url = '$baseUrl/TraCuuDiem/DiemRenLuyen';

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
        var table = document.querySelector("div.row.fullwidth table");

        if (table != null) {
          var rows = table.querySelectorAll("tr");

          // Tách dữ liệu từ các hàng trong bảng
          List<Map<String, String>> cardData = [];

          for (var row in rows.skip(1)) {
            var cells = row.querySelectorAll("td");
            if (cells.length >= 2) {
              cardData.add({
                'Tổng khóa': cells[0].text.trim(),
                'Xếp loại khóa': cells[1].text.trim(),
              });
            }
          }

          setState(() {
            _cardData = cardData;
            _isLoading = false; // Tắt trạng thái loading
            _isFetched = true; // Đánh dấu dữ liệu đã được tải
          });
        } else {
          setState(() {
            _cardData = [];
            _isLoading = false;
            _isFetched = true; // Đánh dấu dữ liệu đã được tải
          });
        }
      } else {
        setState(() {
          _cardData = [];
          _isLoading = false;
          _isFetched = true; // Đánh dấu dữ liệu đã được tải
        });
      }
    } catch (e) {
      setState(() {
        _cardData = [];
        _isLoading = false;
        _isFetched = true; // Đánh dấu dữ liệu đã được tải
      });
    } finally {
      ioClient.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tra Cứu Điểm Rèn Luyện'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Hiển thị trạng thái loading
          : _cardData.isEmpty
          ? Center(child: Text('Không có dữ liệu')) // Khi không có dữ liệu
          : ListView.builder(
        itemCount: _cardData.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 4, // Hiệu ứng bóng của Card
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Góc bo tròn
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng khóa: ${_cardData[index]['Tổng khóa']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Xếp loại khóa: ${_cardData[index]['Xếp loại khóa']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _cardData[index]['Xếp loại khóa'] == 'TB. Khá'
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}