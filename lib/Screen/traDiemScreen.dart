import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:provider/provider.dart';
import 'package:hpc_students/include/config.dart';
import 'package:hpc_students/include/cookie_provider.dart';
import 'package:hpc_students/Screen/loginScreen.dart';
import 'package:fl_chart/fl_chart.dart';

class TraDiemScreen extends StatefulWidget {
  @override
  _TraDiemScreenState createState() => _TraDiemScreenState();
}

class _TraDiemScreenState extends State<TraDiemScreen> {
  List<Map<String, String>> scores = []; // Store parsed scores
  List<Map<String, String>> filteredScores = []; // Store filtered scores
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchScores();
  }

  Future<void> fetchScores() async {
    setState(() {
      isLoading = true;
    });

    String? cookie =
        Provider.of<CookieProvider>(context, listen: false).getCookie();
    if (cookie == null || cookie.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Bước 1: Gửi yêu cầu đến Index
    final urlIndex = Uri.parse("$baseUrl/TraCuuDiem/Index");
    final responseIndex = await http.post(urlIndex, headers: {
      'Cookie': cookie,
    });

    if (responseIndex.statusCode == 200) {
      // Bước 2: Gửi yêu cầu lấy thông tin điểm
      final urlScore = Uri.parse(
          "https://sinhvien.bachkhoahanoi.edu.vn/TraCuuDiem/ThongTinDiemSinhVien");
      final responseScore = await http.post(urlScore, headers: {
        'Cookie': cookie,
      });

      if (responseScore.statusCode == 200) {
        // Kiểm tra phản hồi
        if (responseScore.body
            .contains('Object moved to <a href="/">here</a>')) {
          // Phiên đã hết hạn, chuyển hướng về trang đăng nhập
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          // Parse the HTML response
          parseHtml(responseScore.body);
        }
      } else {
        // Xử lý lỗi nếu yêu cầu không thành công
        setState(() {
          scores = []; // Clear scores on error
        });
      }
    } else {
      // Xử lý lỗi nếu yêu cầu không thành công
      setState(() {
        scores = []; // Clear scores on error
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void parseHtml(String htmlString) {
    final document = html.parse(htmlString);
    final rows = document.querySelectorAll('tr'); // Select all rows

    for (var row in rows.skip(1)) {
      // Skip header row
      final cells = row.querySelectorAll('td');
      if (cells.isNotEmpty) {
        String tbchpRaw = cells[6].text.trim();
        String tbchp =
            tbchpRaw.split('|').last.trim(); // Get the second value after '|'

        scores.add({
          'stt': cells[0].text.trim(),
          'maMon': cells[1].text.trim(),
          'tenMon': cells[2].text.trim(),
          'soTinChi': cells[3].text.trim(),
          'diemTP': cells[4].text.trim(),
          'diemThi': cells[5].text.trim(),
          'tbchp': tbchp, // Store the processed TBCHP value
        });
      }
    }
    filteredScores = List.from(scores); // Initialize filtered scores
  }

  Map<String, List<String>> getGradeDistribution() {
    Map<String, List<String>> gradeCount = {
      'A+': [],
      'A': [],
      'B+': [],
      'B': [],
      'C+': [],
      'C': [],
      'D': [],
      'F': [],
    };

    for (var score in scores) {
      double tbchp = double.tryParse(score['tbchp'] ?? '0') ?? 0;
      String grade = convertToGrade(tbchp);
      gradeCount[grade]?.add(score['tenMon'] ?? '');
    }

    return gradeCount;
  }

  String convertToGrade(double tbchp) {
    if (tbchp >= 9) return 'A+';
    if (tbchp >= 8) return 'A';
    if (tbchp >= 7.5) return 'B+';
    if (tbchp >= 6.5) return 'B';
    if (tbchp >= 5.5) return 'C+';
    if (tbchp >= 5) return 'C';
    if (tbchp >= 4) return 'D';
    return 'F';
  }

  List<BarChartGroupData> showingBarGroups() {
    Map<String, List<String>> gradeCount = getGradeDistribution();
    List<BarChartGroupData> barGroups = [];

    gradeCount.forEach((grade, subjects) {
      barGroups.add(BarChartGroupData(
        x: gradeCount.keys.toList().indexOf(grade),
        barRods: [
          BarChartRodData(
            toY: subjects.length.toDouble(),
            color: Colors.primaries[gradeCount.keys.toList().indexOf(grade) %
                Colors.primaries.length],
            width: 30,
          ),
        ],
      ));
    });

    return barGroups;
  }

  double getMaxBarHeight() {
    Map<String, List<String>> gradeCount = getGradeDistribution();
    return gradeCount.values
        .map((subjects) => subjects.length.toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  void showSubjectsForGrade(String grade) {
    Map<String, List<String>> gradeDistribution = getGradeDistribution();
    List<String> subjects = gradeDistribution[grade] ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Môn học đạt ${grade}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: subjects.asMap().entries.map((entry) {
                int index = entry.key + 1; // Start index from 1
                String subject = entry.value;
                String tbchp =
                    scores.firstWhere((s) => s['tenMon'] == subject)['tbchp'] ??
                        '0';
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4.0), // Add spacing
                  child: Text('$index. $subject: $tbchp'),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tra cứu điểm'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SubjectSearchDelegate(
                  scores: scores,
                  onSearch: (query) {
                    setState(() {
                      filteredScores = scores.where((score) {
                        return score['tenMon']!
                            .toLowerCase()
                            .contains(query.toLowerCase());
                      }).toList();
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Text(
                    'Biểu đồ phân bố điểm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      // Handle tap on the chart
                    },
                    child: Container(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index >= 0 &&
                                      index <
                                          getGradeDistribution().keys.length) {
                                    return Text(getGradeDistribution()
                                        .keys
                                        .toList()[index]);
                                  }
                                  return Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          barGroups: showingBarGroups(),
                          gridData: FlGridData(show: false),
                          maxY:
                              getMaxBarHeight(), // Set maxY to the highest bar count
                          barTouchData: BarTouchData(
                            touchCallback: (event, response) {
                              if (event is! FlTapUpEvent) return;
                              if (response == null || response.spot == null)
                                return;

                              final index = response.spot!.touchedBarGroupIndex;
                              final grade =
                                  getGradeDistribution().keys.toList()[index];
                              showSubjectsForGrade(grade);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // List of subjects
                  ListView.builder(
                    itemCount: filteredScores.length,
                    shrinkWrap:
                        true, // Prevent ListView from taking infinite height
                    physics:
                        NeverScrollableScrollPhysics(), // Disable scrolling
                    itemBuilder: (context, index) {
                      final score = filteredScores[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('${score['tenMon']} (${score['maMon']})'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Điểm thành phần: ${score['diemTP']}'),
                              Text('Điểm thi: ${score['diemThi']}'),
                              Text('TBCHP: ${score['tbchp']}'),

                            ],
                          ),
                          trailing: Text('Số tín chỉ: ${score['soTinChi']}'),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class SubjectSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, String>> scores;
  final Function(String) onSearch;

  SubjectSearchDelegate({required this.scores, required this.onSearch});

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = scores
        .where((score) =>
            score['tenMon']!.toLowerCase().contains(query.toLowerCase()))
        .map((score) => score['tenMon'])
        .toList();

    return ListView(
      children: suggestions.map((suggestion) {
        return ListTile(
          title: Text(suggestion!),
          onTap: () {
            // Tách onSearch ra để tránh setState() ngay lập tức
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onSearch(suggestion);
              close(context, suggestion);
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Tách việc gọi onSearch ra sau khi widget đã được render hoàn chỉnh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSearch(query);
      close(context, query);
    });

    return Container(); // Không cần trả về gì ở đây
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch(query);
        },
      ),
      IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          onSearch(query);
          close(context, query);
        },
      ),
    ];
  }
}
