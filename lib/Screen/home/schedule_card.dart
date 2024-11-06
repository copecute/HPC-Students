import 'package:flutter/material.dart';
import 'package:hpc_students/Screen/lichHoc/traCuuLichHocScreen.dart';
import 'package:intl/intl.dart';
import 'package:hpc_students/include/config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:hpc_students/include/cookie_provider.dart';
import 'package:html/parser.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
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
    String? cachedHtmlResponse =
        prefs.getString('cachedScheduleCard'); // Updated variable name
    setState(() {
      htmlResponse = cachedHtmlResponse;
      isLoadingSchedule =
          cachedHtmlResponse == null; // Show loading if no cache
    });
  }

  Future<void> fetchWeeks(String year) async {
    if (!mounted) return;

    setState(() {
      isLoadingWeeks = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/TraCuuLichHoc/LoadTuanThu?Nam_hoc=$year'),
        headers: {
          'Cookie':
              Provider.of<CookieProvider>(context, listen: false).getCookie() ??
                  '',
        },
      );

      if (!mounted) return;

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
        if (mounted) {
          setState(() {
            isLoadingWeeks = false;
          });
        }
        throw Exception('Failed to load weeks');
      }
    } catch (e) {
      print('Error fetching weeks: $e');
      if (mounted) {
        setState(() {
          isLoadingWeeks = false;
        });
      }
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
    if (!mounted) return;

    if (htmlResponse != null) {
      setState(() {
        isLoadingSchedule = false;
      });
      return;
    }

    setState(() {
      isLoadingSchedule = true;
    });

    String? cookie =
        Provider.of<CookieProvider>(context, listen: false).getCookie();
    if (cookie == null || cookie.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      setState(() {
        isLoadingSchedule = false;
      });
      return;
    }

    try {
      Map<String, String> postData = {
        'Nam_hoc': getCurrentAcademicYear(),
        'Tuan_thu': selectedWeek ?? '',
        'selectedDate': DateFormat('yyyy-MM-dd').format(selectedDate!),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': cookie,
        },
        body: postData,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          htmlResponse = response.body;
          isLoadingSchedule = false;
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cachedScheduleCard', htmlResponse!);
      } else {
        if (mounted) {
          setState(() {
            isLoadingSchedule = false;
          });
        }
        throw Exception('Failed to fetch schedule');
      }
    } catch (e) {
      print('Error fetching schedule: $e');
      if (mounted) {
        setState(() {
          isLoadingSchedule = false;
        });
      }
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

    // Get the selected day's index
    int selectedDayIndex =
        selectedDate!.weekday - 1; // Adjust for 0-based index

    // Initialize a map to store the schedule for the selected day
    Map<String, List<Map<String, dynamic>>> schedule = {
      daysOfWeek[selectedDayIndex]: []
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
            if (i - 1 == selectedDayIndex) {
              // Use selectedDayIndex instead of todayIndex
              schedule[daysOfWeek[selectedDayIndex]]?.add({
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

    // Build the UI for the selected day
    String day = daysOfWeek[selectedDayIndex];
    var daySessions = schedule[day];

    if (daySessions != null && daySessions.length > 1) {
      cards.add(
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: daySessions.length,
            itemBuilder: (context, index) {
              var session = daySessions[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Học phần: ${session['hocPhan']}'),
                      Text('Phòng: ${session['room']}'),
                      Text('Giảng viên: ${session['teacher']}'),
                      Text(
                          'Tiết: ${session['periodStart']} - ${session['periodEnd']}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else if (daySessions == null || daySessions.isEmpty) {
      cards.add(
        Card(
          margin: EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hôm nay không có lịch học!'),
              ],
            ),
          ),
        ),
      );
    }

    // Add a full-width card if there's only one session
    if (daySessions != null && daySessions.length == 1) {
      var session = daySessions[0];
      cards.add(
        Card(
          margin: EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Học phần: ${session['hocPhan']}'),
                Text('Phòng: ${session['room']}'),
                Text('Giảng viên: ${session['teacher']}'),
                Text(
                    'Tiết: ${session['periodStart']} - ${session['periodEnd']}'),
              ],
            ),
          ),
        ),
      );
    }

    return cards;
  }

  Future<void> refreshData() async {
    if (!mounted) return;

    await fetchWeeks(getCurrentAcademicYear());
    if (selectedWeek != null && mounted) {
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
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lịch học ${DateFormat('dd/MM/yyyy').format(selectedDate!)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back),
                                onPressed: () {
                                  setState(() {
                                    selectedDate = selectedDate!
                                        .subtract(Duration(days: 1));
                                    refreshData(); // Refresh the schedule for the previous day
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.schedule), // Today button icon
                                onPressed: () {
                                  setState(() {
                                    selectedDate =
                                        DateTime.now(); // Set to today's date
                                    refreshData(); // Refresh the schedule for today
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_forward),
                                onPressed: () {
                                  setState(() {
                                    selectedDate =
                                        selectedDate!.add(Duration(days: 1));
                                    refreshData(); // Refresh the schedule for the next day
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      ..._buildScheduleCards(htmlResponse!).map((card) {
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
                    ],
                  ),
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
