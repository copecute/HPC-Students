import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class LichHocCachedScreen extends StatefulWidget {
  @override
  _LichHocCachedScreenState createState() => _LichHocCachedScreenState();
}

class _LichHocCachedScreenState extends State<LichHocCachedScreen> {
  String? cachedHtmlResponse;
  String? cachedSelectedWeek;

  @override
  void initState() {
    super.initState();
    _loadCachedSchedule();
  }

  Future<void> _loadCachedSchedule() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedSchedule = prefs.getString('cachedSchedule');
    String? cachedWeek =
        prefs.getString('cachedSelectedWeek'); // Load cached week text
    setState(() {
      cachedHtmlResponse = cachedSchedule;
      cachedSelectedWeek = cachedWeek; // Set the cached week text
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch học đã lưu'),
      ),
      body: cachedHtmlResponse != null
          ? SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    cachedSelectedWeek != null
                        ? '$cachedSelectedWeek' // Display cached week text
                        : 'Không có tuần đã lưu.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  HtmlWidget(cachedHtmlResponse!),
                ],
              ),
            )
          : Center(child: Text('Không có lịch học đã lưu.')),
    );
  }
}
