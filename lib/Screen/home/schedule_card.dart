import 'package:flutter/material.dart';
import 'package:hpc_students/Screen/lichHoc/traCuuLichHocScreen.dart';
import 'package:intl/intl.dart';
import 'package:hpc_students/include/config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:hpc_students/include/cookie_provider.dart';
import 'package:html/parser.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:hpc_students/Screen/loginScreen.dart';

class ScheduleCard extends StatefulWidget {
  @override
  _ScheduleCardState createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  String? selectedWeek;
  List<Map<String, String>> weeks = [];
  String? htmlResponse;
  String url = '$baseUrl/TraCuuLichHoc/DanhSachTuan';
  bool isLoadingWeeks = false;
  bool isLoadingSchedule = false;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    fetchWeeks(getCurrentAcademicYear());
    calculateWeekFromDate(selectedDate!);
    _loadCachedSchedule();
  }

  String getCurrentAcademicYear() {
    int year = selectedDate!.year;
    return '$year-${year + 1}'; // Return the current academic year
  }

  Future<void> _loadCachedSchedule() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedHtmlResponse = prefs.getString('cachedSchedule');
    setState(() {
      htmlResponse = cachedHtmlResponse;
      isLoadingSchedule =
          cachedHtmlResponse == null; // Show loading if no cache
    });
  }

  Future<void> fetchWeeks(String year) async {
    setState(() {
      isLoadingWeeks = true;
    });

    final response = await http.get(
      Uri.parse('$baseUrl/TraCuuLichHoc/LoadTuanThu?Nam_hoc=$year'),
      headers: {
        'Cookie':
            Provider.of<CookieProvider>(context, listen: false).getCookie() ??
                '',
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

  void calculateWeekFromDate(DateTime date) {
    for (var week in weeks) {
      var weekText = week['text']!;
      var dates = weekText.split('[')[1].split(']')[0].split('--');
      var startDate =
          DateFormat('dd/MM/yyyy').parse(dates[0].split('Từ ')[1].trim());
      var endDate =
          DateFormat('dd/MM/yyyy').parse(dates[1].split('Đến ')[1].trim());

      if (date.isAfter(startDate.subtract(Duration(days: 1))) &&
          date.isBefore(endDate.add(Duration(days: 1)))) {
        setState(() {
          selectedWeek = week['value'];
        });
        break;
      }
    }

    if (selectedWeek != null) {
      fetchSchedule();
    }
  }

  Future<void> fetchSchedule() async {
    setState(() {
      isLoadingSchedule = true;
    });

    String? cookie =
        Provider.of<CookieProvider>(context, listen: false).getCookie();
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

    Map<String, String> postData = {
      'Nam_hoc': getCurrentAcademicYear(),
      'Tuan_thu': selectedWeek ?? '',
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cookie': cookie,
      },
      body: postData,
    );

    if (response.statusCode == 200) {
      setState(() {
        htmlResponse = response.body;
        isLoadingSchedule = false;
      });

      // Cache the HTML response
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cachedSchedule', htmlResponse!); // Save to cache
    } else {
      setState(() {
        isLoadingSchedule = false;
      });
      throw Exception('Failed to fetch schedule');
    }
  }

  List<Widget> _buildScheduleCards(String htmlResponse) {
    var document = html.parse(htmlResponse);
    List<Widget> cards = [];
    var rows = document.querySelectorAll('table tbody tr');
    List<String> daysOfWeek = [
      "Thứ Hai",
      "Thứ Ba",
      "Thứ Tư",
      "Thứ Năm",
      "Thứ Sáu",
      "Thứ Bảy",
      "Chủ Nhật"
    ];

    // Get today's day index
    int todayIndex = DateTime.now().weekday - 1; // Adjust for 0-based index

    // Initialize a map to store the schedule for today
    Map<String, List<Map<String, dynamic>>> schedule = {
      daysOfWeek[todayIndex]: []
    };

    for (var row in rows) {
      var cells = row.querySelectorAll('td');
      if (cells.length > 1) {
        String period = cells[0].text.trim(); // Lấy số tiết từ ô đầu tiên

        for (var i = 1; i < cells.length; i++) {
          var cell = cells[i];
          var content = cell.innerHtml.trim();

          // Bỏ qua ô nếu rỗng hoặc chỉ chứa số
          if (content.isNotEmpty && !RegExp(r'^\d+$').hasMatch(content)) {
            int rowspan = int.tryParse(cell.attributes['rowspan'] ?? '1') ?? 1;

            // Xóa nội dung của ô đã merge nếu rowspan lớn hơn 1
            for (int j = 1; j < rowspan; j++) {
              if (rows.length > (rows.indexOf(row) + j)) {
                var nextRow = rows[rows.indexOf(row) + j];
                var nextCells = nextRow.querySelectorAll('td');
                if (nextCells.length > i) {
                  nextCells[i].innerHtml = ''; // Xóa nội dung của ô bị merge
                }
              }
            }

            // Tính số tiết kết thúc
            int periodEnd = int.parse(period) + rowspan - 1;
            print(cell.innerHtml);
            // Lấy thông tin từ content của cell
            String hocPhan = '';
            String phong = '';
            String giaoVien = '';

            // Sử dụng RegExp để tách thông tin học phần, phòng, giáo viên từ nội dung
            RegExp hocPhanRegExp = RegExp(r'Học phần: (.+?)<br>');
            RegExp phongRegExp = RegExp(r'Tên phòng: (.+?)<br>');
            RegExp giaoVienRegExp = RegExp(r'GV: (.+?)$'); //lấy đến hết dòng

            var hocPhanMatch = hocPhanRegExp.firstMatch(content);
            if (hocPhanMatch != null) {
              hocPhan = hocPhanMatch.group(1) ?? '';
            }

            var phongMatch = phongRegExp.firstMatch(content);
            if (phongMatch != null) {
              phong = phongMatch.group(1) ?? '';
            }

            var giaoVienMatch = giaoVienRegExp.firstMatch(content);
            if (giaoVienMatch != null) {
              giaoVien = giaoVienMatch.group(1) ?? '';
            }

            // Thêm thông tin vào lịch hôm nay
            if (i - 1 == todayIndex) {
              schedule[daysOfWeek[todayIndex]]?.add({
                'hocPhan': hocPhan, // Tên học phần
                'periodStart': period, // Tiết bắt đầu
                'periodEnd': periodEnd, // Tiết kết thúc
                'room': phong, // Tên phòng
                'teacher': giaoVien, // Tên giáo viên
              });
            }
          }
        }
      }
    }

    // Build the UI for today
    String day = daysOfWeek[todayIndex];
    var daySessions = schedule[day];
    String dayContent =
        '<strong>Lịch học $day (${DateFormat('d/M').format(DateTime.now())})</strong><br/>';

    if (daySessions != null && daySessions.isNotEmpty) {
      for (var session in daySessions) {
        dayContent += 'Học phần: ${session['hocPhan']}<br/>'
            'Phòng: ${session['room']}<br/>'
            'Giảng viên: ${session['teacher']}<br/>'
            'Tiết: ${session['periodStart']} - ${session['periodEnd']}';
      }
    } else {
      dayContent += 'Hôm nay không có lịch học!';
    }
    cards.add(
      Card(
        margin: EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: HtmlWidget(
            dayContent,
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );

    return cards;
  }

  Future<void> refreshData() async {
    // Refresh the weeks and schedule
    await fetchWeeks(getCurrentAcademicYear());
    if (selectedWeek != null) {
      await fetchSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: isLoadingSchedule
          ? Center(child: CircularProgressIndicator())
          : htmlResponse != null
              ? Column(
                  children: _buildScheduleCards(htmlResponse!).map((card) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TraCuuLichHocScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity, // Set card width to 100%
                        child: card,
                      ),
                    );
                  }).toList(),
                )
              : Column(
                  children: _buildScheduleCards(
                          'Không có lịch học nào! click vào đây để xem')
                      .map((card) {
                    return GestureDetector(
                      onTap: () {
                        // Navigate to lichHoc screen when the card is tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TraCuuLichHocScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity, // Set card width to 100%
                        child: card,
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
