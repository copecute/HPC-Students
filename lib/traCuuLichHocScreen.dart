import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hpc_students/config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'cookie_provider.dart'; // Import CookieProvider
import 'package:html/parser.dart' as html;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'loginScreen.dart';

class TraCuuLichHocScreen extends StatefulWidget {
  @override
  _TraCuuLichHocScreenState createState() => _TraCuuLichHocScreenState();
}

class _TraCuuLichHocScreenState extends State<TraCuuLichHocScreen> {
  String? selectedWeek;
  List<Map<String, String>> weeks = [];
  String? htmlResponse;
  String url = '$baseUrl/TraCuuLichHoc/DanhSachTuan';
  String? cookie;
  Map<String, String> postData = {};
  bool isLoadingWeeks = false;
  bool isLoadingSchedule = false;
  DateTime? selectedDate; // Biến lưu trữ ngày được chọn

  @override
  void initState() {
    super.initState();
    // Tự động load dữ liệu cho ngày hiện tại khi mở màn hình
    selectedDate = DateTime.now();
    fetchWeeks(getCurrentAcademicYear()); // Lấy danh sách tuần với năm hiện tại
    calculateWeekFromDate(selectedDate!); // Tính tuần cho ngày hiện tại
  }

  Future<void> fetchWeeks(String year) async {
    setState(() {
      isLoadingWeeks = true;
    });

    final response = await http.get(
      Uri.parse('$baseUrl/TraCuuLichHoc/LoadTuanThu?Nam_hoc=$year'),
      headers: {
        'Cookie': Provider.of<CookieProvider>(context, listen: false).getCookie() ?? '',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        weeks = [];
        var document = html.parse(response.body);
        var options = document.querySelectorAll('select#cmbTuanThu option');

        for (var option in options) {
          var value = option.attributes['value'];
          var text = option.text;
          if (value != '-1') {
            weeks.add({'value': value!, 'text': text});
          }
        }
        isLoadingWeeks = false;
      });

      // Tự động fetch schedule khi có dữ liệu tuần và năm học
      if (weeks.isNotEmpty) {
        calculateWeekFromDate(selectedDate!);
      }
    } else {
      setState(() {
        isLoadingWeeks = false;
      });
      throw Exception('Failed to load weeks');
    }
  }

  // Hàm tính tuần dựa trên ngày đã chọn
  void calculateWeekFromDate(DateTime date) {
    for (var week in weeks) {
      var weekText = week['text']!;
      var dates = weekText.split('[')[1].split(']')[0].split('--');
      var startDate = DateFormat('dd/MM/yyyy').parse(dates[0].split('Từ ')[1].trim());
      var endDate = DateFormat('dd/MM/yyyy').parse(dates[1].split('Đến ')[1].trim());

      if (date.isAfter(startDate.subtract(Duration(days: 1))) && date.isBefore(endDate.add(Duration(days: 1)))) {
        setState(() {
          selectedWeek = week['value'];
        });
        break;
      }
    }

    // Tự động fetch schedule khi có ngày và tuần
    if (selectedWeek != null) {
      fetchSchedule();
    }
  }

  Future<void> fetchSchedule() async {
    setState(() {
      isLoadingSchedule = true;
    });

    String? cookie = Provider.of<CookieProvider>(context, listen: false).getCookie();
    if (cookie == null || cookie.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      setState(() {
        isLoadingSchedule = false;
      });
      return;
    }

    postData = {
      'Nam_hoc': getCurrentAcademicYear(),
      'Tuan_thu': selectedWeek ?? '',
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
        htmlResponse = response.body;
        isLoadingSchedule = false;
      });
    } else {
      setState(() {
        isLoadingSchedule = false;
      });
      throw Exception('Failed to fetch schedule');
    }
  }

  String getCurrentAcademicYear() {
    int year = selectedDate!.year;
    return year.toString() + '-' + (year + 1).toString(); // Ví dụ: 2024-2025
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
            // Input date picker
            TextFormField(
              decoration: InputDecoration(labelText: 'Chọn ngày'),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  // Thiết lập firstDate là 8 năm trước
                  firstDate: DateTime(DateTime.now().year - 8, 8, 5),
                  // Thiết lập lastDate là 1 năm sau
                  lastDate: DateTime(DateTime.now().year + 1, 8, 3),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                  calculateWeekFromDate(pickedDate);
                }
              },
              controller: TextEditingController(
                text: selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate!) : '',
              ),
            ),
            SizedBox(height: 20),
            // Hiển thị tuần tương ứng với ngày chọn
            Text(
              selectedWeek != null
                  ? weeks.firstWhere((week) => week['value'] == selectedWeek)['text']!
                  : '',
            ),
            SizedBox(height: 20),
            if (isLoadingSchedule)
              CircularProgressIndicator()
            else if (htmlResponse != null)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: HtmlWidget(htmlResponse!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
