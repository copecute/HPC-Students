import 'package:flutter/material.dart';
import 'package:hpc_students/include/config.dart';
import 'package:http/http.dart' as http; // Thêm import cho http
import 'dart:convert'; // Thêm import cho json
import 'package:html/parser.dart' as htmlParser; // Thêm import cho html

class TraCuuVanBangScreen extends StatefulWidget {
  // Đổi tên lớp
  @override
  _TraCuuVanBangScreenState createState() =>
      _TraCuuVanBangScreenState(); // Đổi tên phương thức tạo trạng thái
}

class _TraCuuVanBangScreenState extends State<TraCuuVanBangScreen> {
  // Đổi tên lớp trạng thái
  final TextEditingController maSinhVienController = TextEditingController();
  final TextEditingController soHieuController = TextEditingController();
  Map<String, String>? result; // Thay đổi kiểu dữ liệu
  bool _isLoading = false; // Biến để theo dõi trạng thái loading

  Future<void> search() async {
    setState(() {
      _isLoading = true; // Bắt đầu loading
    });

    final maSv = maSinhVienController.text;
    final soHieu = soHieuController.text;
    final response = await http.get(Uri.parse(
        '$baseUrl/TraCuuVanBang/_Chitiet?Ma_sv=$maSv&So_hieu=$soHieu'));

    if (response.statusCode == 200) {
      // Phân tích HTML
      var document = htmlParser.parse(response.body);
      var studentInfo =
          document.querySelectorAll('div.col-md-3 ul.list-group li');

      if (studentInfo.isNotEmpty) {
        Map<String, String> data = {};
        for (var item in studentInfo) {
          var title = item.querySelector('b')?.text.replaceAll(':', '').trim();
          var value = item.text
              .replaceAll(item.querySelector('b')?.text ?? '', '')
              .trim();
          if (title != null) {
            data[title] = value;
          }
        }
        setState(() {
          result = data; // Cập nhật kết quả
        });
      } else {
        print('Không tìm thấy thông tin sinh viên.');
        setState(() {
          result = null; // Hoặc xử lý theo cách khác
        });
      }
    } else {
      print('Lỗi: ${response.statusCode}');
      setState(() {
        result = null; // Hoặc xử lý theo cách khác
      });
    }

    setState(() {
      _isLoading = false; // Kết thúc loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tra Cứu Văn Bằng')),
      body: SingleChildScrollView(
        // Sử dụng SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: maSinhVienController,
              decoration: InputDecoration(labelText: 'Mã sinh viên'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: soHieuController,
              decoration: InputDecoration(labelText: 'Số hiệu văn bằng'),
            ),
            SizedBox(height: 10),
            Text(
              'Lưu ý: có thể tra bằng số hiệu văn bằng hoặc mã sinh viên hoặc cả hai.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: search,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2d59a4),
                padding: EdgeInsets.symmetric(vertical: 15),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Tìm kiếm',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_isLoading) // Hiển thị loading
              Center(child: CircularProgressIndicator()),
            if (result != null && !_isLoading) ...[
              // Hiển thị kết quả dưới dạng danh sách card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var entry in result!.entries)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(
                                '${entry.key}:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                '${entry.value}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Divider(), // Thêm đường phân cách giữa các mục
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
