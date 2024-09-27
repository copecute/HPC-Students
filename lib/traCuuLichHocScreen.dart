import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'cookie_provider.dart'; // Import CookieProvider
import 'package:html/parser.dart' as html;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class TraCuuLichHocScreen extends StatefulWidget {
  @override
  _TraCuuLichHocScreenState createState() => _TraCuuLichHocScreenState();
}

class _TraCuuLichHocScreenState extends State<TraCuuLichHocScreen> {
  String? selectedYear; // Năm học được chọn
  String? selectedWeek; // Tuần được chọn
  List<Map<String, String>> weeks = []; // Danh sách tuần với cả value và text
  String? htmlResponse; // Biến lưu trữ phản hồi HTML
  String url = 'https://sinhvien.bachkhoahanoi.edu.vn/TraCuuLichHoc/DanhSachTuan'; // URL
  String? cookie; // Cookie
  Map<String, String> postData = {}; // Biến lưu trữ dữ liệu post

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchWeeks(String year) async {
    final response = await http.get(
      Uri.parse('https://sinhvien.bachkhoahanoi.edu.vn/TraCuuLichHoc/LoadTuanThu?Nam_hoc=$year'),
      headers: {
        'Cookie': Provider.of<CookieProvider>(context, listen: false).getCookie() ?? '', // Thêm cookie vào header
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        weeks = []; // Xóa danh sách tuần hiện tại

        // Phân tích HTML và lấy thông tin tuần
        var document = html.parse(response.body);
        var options = document.querySelectorAll('select#cmbTuanThu option');

        // Thêm tuần vào danh sách
        for (var option in options) {
          var value = option.attributes['value'];
          var text = option.text;
          if (value != '-1') { // Bỏ qua tùy chọn "--- Chọn tuần ---"
            weeks.add({'value': value!, 'text': text}); // Lưu trữ cả value và text
          }
        }
      });
    } else {
      throw Exception('Failed to load weeks');
    }
  }

  Future<void> fetchSchedule() async {
    cookie = Provider.of<CookieProvider>(context, listen: false).getCookie() ?? ''; // Lấy cookie

    // Dữ liệu POST để tra cứu lịch học
    postData = {
      'Nam_hoc': selectedYear ?? '',
      'Tuan_thu': selectedWeek ?? '', // Giữ nguyên, selectedWeek chứa value
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cookie': cookie!,
      },
      body: postData,
    );

    if (response.statusCode == 200) {
      setState(() {
        htmlResponse = response.body; // Lưu trữ phản hồi HTML
      });
    } else {
      throw Exception('Failed to fetch schedule');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tra cứu lịch học'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Chọn năm học
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Năm học'),
              items: List.generate(9, (index) {
                int year = DateTime.now().year - 8 + index;
                return DropdownMenuItem(
                  value: '$year-${year + 1}',
                  child: Text('$year-${year + 1}'),
                );
              }),
              onChanged: (value) {
                setState(() {
                  selectedYear = value;
                  selectedWeek = null; // Đặt lại tuần khi năm học thay đổi
                });
                if (value != null) {
                  fetchWeeks(value); // Gọi hàm để lấy tuần khi chọn năm học
                }
              },
            ),
            // Chọn tuần
            DropdownButtonFormField<Map<String, String>>(
              decoration: InputDecoration(labelText: 'Tuần'),
              items: weeks.map((week) {
                return DropdownMenuItem<Map<String, String>>(
                  value: week,
                  child: Text(week['text']!), // Hiển thị văn bản tuần
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedWeek = value?['value']; // selectedWeek sẽ lưu trữ value
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (selectedYear != null && selectedWeek != null) {
                  fetchSchedule(); // Gọi hàm để tra cứu lịch học
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng chọn năm học và tuần')),
                  );
                }
              },
              child: Text('Tra cứu lịch học'),
            ),
            SizedBox(height: 20),
            // Hiển thị thông tin URL, cookie và postData
            Text(' ', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text('Cookie: ${cookie ?? ''}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text('Dữ liệu POST: ${postData.isNotEmpty ? postData.toString() : 'Chưa có dữ liệu'}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            // Hiển thị kết quả lịch học nếu có
            if (htmlResponse != null)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Cho phép cuộn ngang
                  child: HtmlWidget(htmlResponse!), // Hiển thị nội dung HTML
                ),
              ),
          ],
        ),
      ),
    );
  }
}
