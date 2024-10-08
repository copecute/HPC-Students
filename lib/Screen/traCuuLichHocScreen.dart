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
    if (cachedHtmlResponse != null) {
      setState(() {
        htmlResponse = cachedHtmlResponse;
        isLoadingSchedule = false;
      });
    }
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
        'Cookie': cookie!,
      },
      body: postData,
    );

    if (response.statusCode == 200) {
      String modifiedHtmlResponse = response.body.replaceAll(
          '<tr style="background-color:#f9f9fa">',
          '<tr style="text-align:center;vertical-align:middle;">'); // Replace specific <tr> style with a generic <tr>

      // Replace table and cell styles with inline styles
      modifiedHtmlResponse = modifiedHtmlResponse.replaceAll(
        '<table',
        '''
        <table style="width: 100%; border-collapse: collapse; box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);"
        ''',
      );

      modifiedHtmlResponse = modifiedHtmlResponse.replaceAll(
        '<th scope="col"',
        '''
        <th scope="col" style="border: 1px solid #ddd; padding: 12px; text-align: center; background: #2d58a3; color: white; font-weight: bold; font-size: 16px;"
        ''',
      );

      modifiedHtmlResponse = modifiedHtmlResponse.replaceAll(
        '<td>',
        '''
        <td style="border: 1px solid #ddd; padding: 10px; text-align: center; vertical-align: middle; background: unset;"
        ''',
      );

      modifiedHtmlResponse = modifiedHtmlResponse.replaceAll(
        '<td style="',
        '''
        <td style="border: 1px solid #ddd; padding: 10px; text-align: center; vertical-align: middle; background: unset; "
        ''',
      );

      modifiedHtmlResponse = modifiedHtmlResponse.replaceAllMapped(
        RegExp(r'<td rowspan="\d+" style="'),
            (match) => '<td rowspan="${match.group(0)!.split('"')[1]}" style="color:black;border: 1px solid #ddd; padding: 10px; text-align: center; vertical-align: middle; ',
      );

      modifiedHtmlResponse = modifiedHtmlResponse.replaceAll(
        '<tr',
        '''
        <tr style="transition: background-color 0.3s;"
        onmouseover="this.style.backgroundColor='#e0e0e0'" onmouseout="this.style.backgroundColor=''"
        ''',
      );

      setState(() {
        htmlResponse = modifiedHtmlResponse;
        isLoadingSchedule = false;
      });

      // Cache dữ liệu lịch học sau khi tải thành công
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cachedSchedule', htmlResponse!); // Save to cache
    } else {
      setState(() {
        isLoadingSchedule = false;
      });
      throw Exception('Không thể lấy lịch học');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tra cứu lịch học'),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData, // Gọi hàm refreshData khi kéo xuống
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
              SizedBox(height: 5),
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
      ),
    );
  }
}
