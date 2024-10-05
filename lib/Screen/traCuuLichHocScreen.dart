import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hpc_students/include/config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:hpc_students/include/cookie_provider.dart';
import 'package:html/parser.dart' as html;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:hpc_students/Screen/loginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;

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
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    fetchWeeks(getCurrentAcademicYear());
    calculateWeekFromDate(selectedDate!);
    _loadCachedSchedule();
  }

  Future<void> _loadCachedSchedule() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedHtmlResponse = prefs.getString('cachedSchedule');
    setState(() {
      htmlResponse = cachedHtmlResponse;
      isLoadingSchedule =
          cachedHtmlResponse == null; // Only show loading if no cache is found
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

    postData = {
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

  String getCurrentAcademicYear() {
    int year = selectedDate!.year;
    return year.toString() + '-' + (year + 1).toString();
  }

  Future<void> refreshData() async {
    // Tải lại danh sách tuần và lịch
    await fetchWeeks(getCurrentAcademicYear());
    if (selectedWeek != null) {
      await fetchSchedule();
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

    // Initialize a map to track classes for each day with non-null empty lists
    Map<String, List<Widget>> dayClasses = {
      for (var day in daysOfWeek) day: []
    };

    for (var row in rows) {
      var cells = row.querySelectorAll('td');
      if (cells.length > 1) {
        String timeSlot = cells[0].text.trim();
        int startingPeriod =
            int.tryParse(timeSlot) ?? 0; // Parse the starting period
        for (var i = 1; i < cells.length - 1; i++) {
          // Skip first and last column which are time slots
          var cell = cells[i];
          var content = cell.text.trim();
          if (cell.attributes.containsKey('rowspan') && content.isNotEmpty) {
            int rowspan = int.parse(cell.attributes['rowspan']!);
            var details = content.split(
                '<br>'); // Assuming details are separated by <br> tags in HTML

            // Calculate the adjusted day index based on the starting period
            int dayIndex = i - 1;
            if (startingPeriod == 8) {
              dayIndex = (dayIndex + 2) %
                  7; // Shift the day by 2, wrap around using modulo
            }

            // Safely add details to the corresponding adjusted day's list
            List<Widget>? dayList = dayClasses[daysOfWeek[dayIndex]];
            if (dayList != null) {
              dayList.add(
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Tiết: $timeSlot - ${int.parse(timeSlot) + rowspan - 1}',
                          style: TextStyle(fontSize: 16)),
                      for (var detail in details)
                        Text(detail, style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              );
            }
          }
        }
      }
    }

    // Add cards for each day, including "Nghỉ" for days without classes
    for (var day in daysOfWeek) {
      List<Widget>? dayList = dayClasses[day];
      if (dayList != null && dayList.isEmpty) {
        cards.add(
          Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(day),
              subtitle: Text('Nghỉ', style: TextStyle(color: Colors.red)),
            ),
          ),
        );
      } else if (dayList != null) {
        cards.add(
          Card(
            margin: EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...dayList,
                ],
              ),
            ),
          ),
        );
      }
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tra cứu lịch học'),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Chọn ngày'),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(DateTime.now().year - 8, 8, 5),
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
                  text: selectedDate != null
                      ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                      : '',
                ),
              ),
              SizedBox(height: 20),
              Text(
                selectedWeek != null
                    ? weeks.firstWhere(
                        (week) => week['value'] == selectedWeek)['text']!
                    : '',
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppBar(
                              title: Text("Bảng lịch học"),
                              automaticallyImplyLeading: false,
                              actions: [
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () => Navigator.of(context).pop(),
                                )
                              ],
                            ),
                            htmlResponse == null
                                ? Center(child: CircularProgressIndicator())
                                : Expanded(
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
                      );
                    },
                  );
                },
                child: Text('Xem bảng',
                  style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2d59a4),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
              if (isLoadingSchedule)
                Center(child: CircularProgressIndicator())
              else if (htmlResponse != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: _buildScheduleCards(htmlResponse!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
