import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import '../include/cookie_provider.dart';
import '../include/config.dart'; // File config chứa baseUrl
import 'loginScreen.dart'; // Thêm đường dẫn đến file đăng nhập
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class TraCuuHocPhiScreen extends StatefulWidget {
  @override
  _TraCuuHocPhiScreenState createState() => _TraCuuHocPhiScreenState();
}

class _TraCuuHocPhiScreenState extends State<TraCuuHocPhiScreen> {
  List<Map<String, String>> _hocPhiData = [];
  bool _isLoading = true;
  bool _isDataFetched = false; // Flag to check if data has been fetched

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data on initialization
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData =
        prefs.getString('cachedHocPhiData'); // Load cached data

    if (cachedData != null) {
      // If cached data exists, parse it and update the UI
      List<dynamic> jsonData = jsonDecode(cachedData); // Decode JSON
      _hocPhiData = List<Map<String, String>>.from(jsonData.map((item) =>
          Map<String, String>.from(item))); // Cast to List<Map<String, String>>
      setState(() {
        _isLoading = false; // Set loading to false
        _isDataFetched = true; // Mark data as fetched
      });
    } else {
      // If no cached data, fetch from the server
      await _fetchData();
    }
  }

  Future<void> _fetchData() async {
    String? cookie =
        Provider.of<CookieProvider>(context, listen: false).getCookie();

    if (cookie == null || cookie.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LoginScreen()), // Redirect to login if no cookie
      );
      return;
    }

    final url = '$baseUrl/TraCuuHocPhi/Index';
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    final ioClient = IOClient(httpClient);

    try {
      final response = await ioClient.get(
        Uri.parse(url),
        headers: {
          'Cookie': cookie, // Send cookie for authentication
        },
      );

      if (response.statusCode == 200) {
        var document = htmlParser.parse(response.body);
        var elements = document.querySelectorAll("div.news");

        if (elements.isNotEmpty) {
          var newsDiv = elements.first;
          _hocPhiData = _parseHocPhiData(newsDiv);
        } else {
          _hocPhiData.add({'error': 'Không tìm thấy dữ liệu!'});
        }

        setState(() {
          _isLoading = false; // Set loading to false
          _isDataFetched = true; // Mark data as fetched
        });

        // Cache the data
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'cachedHocPhiData', jsonEncode(_hocPhiData)); // Save to cache
      } else {
        setState(() {
          _hocPhiData.add({'error': 'Lỗi tải dữ liệu'});
          _isLoading = false; // Set loading to false
          _isDataFetched = true; // Mark data as fetched
        });
      }
    } catch (e) {
      setState(() {
        _hocPhiData.add({'error': 'Kiểm tra kết nối Internet!'});
        _isLoading = false; // Set loading to false
        _isDataFetched = true; // Mark data as fetched
      });
    } finally {
      ioClient.close();
    }
  }

  List<Map<String, String>> _parseHocPhiData(var newsDiv) {
    List<Map<String, String>> data = [];

    // Lấy tổng số tiền phải nộp
    var totalAmountLabel = newsDiv
            .querySelector("div.form-group:nth-child(1) label:nth-child(2)")
            ?.text
            .trim() ??
        '';
    var totalPaidLabel = newsDiv
            .querySelector("div.form-group:nth-child(2) label:nth-child(2)")
            ?.text
            .trim() ??
        '';
    var balanceLabel = newsDiv
            .querySelector("div.form-group:nth-child(3) label:nth-child(2)")
            ?.text
            .trim() ??
        '';
    var tableRows = newsDiv
        .querySelectorAll("table#gvTaiChinh tbody tr:not(.table-header)");
    for (var row in tableRows) {
      var cells = row.querySelectorAll("td");
      if (cells.length > 0) {
        data.add({
          'hocKy': cells[0].text.trim(),
          'namHoc': cells[1].text.trim(),
          'mucHocPhi': cells[2].text.trim(),
          'mienGiam': cells[3].text.trim(),
          'soTienPhaiNop': cells[4].text.trim(),
          'soTienDaNop': cells[5].text.trim(),
          'thuaThieu': cells[6].text.trim(),
        });
      }
    }

    // Add new entries for total amounts
    data.add({
      'title': 'Tổng số tiền phải nộp',
      'value': totalAmountLabel,
    });
    data.add({
      'title': 'Tổng số tiền đã nộp',
      'value': totalPaidLabel,
    });
    data.add({
      'title': 'Số tiền thừa/thiếu',
      'value': balanceLabel,
    });

    return data;
  }

  double _convertCurrencyToDouble(String currency) {
    return double.tryParse(currency.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
  }

  double _calculateTotal(List<Map<String, String>> data, String key) {
    double total = 0.0;
    for (var item in data) {
      if (item.containsKey(key)) {
        total += _convertCurrencyToDouble(item[key]!);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    double tongSoTienPhaiNop = _calculateTotal(_hocPhiData, 'soTienPhaiNop');
    double tongSoTienDaNop = _calculateTotal(_hocPhiData, 'soTienDaNop');
    double tongThuaThieu = _calculateTotal(_hocPhiData, 'thuaThieu');

    // Group data by academic year
    Map<String, List<Map<String, String>>> groupedData = {};
    for (var item in _hocPhiData) {
      String yearKey = item['namHoc'] ?? ''; // Provide a default value
      if (yearKey.isNotEmpty) {
        // Check if yearKey is not empty
        (groupedData[yearKey] ??= []).add(item);
      }
    }

    List<String> years = groupedData.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Tra Cứu Học Phí'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    // Add a Row to contain the PieChart and the indicators
                    children: [
                      Expanded(
                        child: Container(
                          height: 300, // Set a fixed height for the PieChart
                          child: Card(
                            margin: EdgeInsets.all(8.0),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: PieChart(
                                      PieChartData(
                                        sections: [
                                          PieChartSectionData(
                                            value: tongSoTienDaNop,
                                            title: 'Đã nộp',
                                            color: Colors.green,
                                            radius: 50,
                                          ),
                                          PieChartSectionData(
                                            value: tongThuaThieu,
                                            title: 'Thừa/thiếu',
                                            color: Colors.red,
                                            radius: 50,
                                          ),
                                        ],
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 40,
                                        pieTouchData: PieTouchData(
                                          touchCallback: (FlTouchEvent event,
                                              PieTouchResponse?
                                                  pieTouchResponse) {
                                            if (event is FlTapUpEvent &&
                                                pieTouchResponse != null) {
                                              int touchedIndex =
                                                  pieTouchResponse
                                                      .touchedSection!
                                                      .touchedSectionIndex;
                                              String title = '';
                                              String content = '';
                                              if (touchedIndex == 0) {
                                                title = 'Số tiền đã nộp';
                                                content = tongSoTienDaNop
                                                        .toStringAsFixed(0) +
                                                    ' ₫';
                                              } else if (touchedIndex == 1) {
                                                title = 'Số tiền thừa/thiếu';
                                                content = tongThuaThieu
                                                        .toStringAsFixed(0) +
                                                    ' ₫';
                                              }
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: Text(title),
                                                  content: Text(content),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text('OK'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Add indicators here inside the same Card
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Indicator(
                                        color: Colors.green,
                                        text: 'Đã nộp',
                                        isSquare: true,
                                      ),
                                      SizedBox(height: 4),
                                      Indicator(
                                        color: Colors.red,
                                        text: 'Thừa/thiếu',
                                        isSquare: true,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Existing Card widget to display total amounts
                  Card(
                    margin: EdgeInsets.all(8.0),
                    elevation: 4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRichText('Tổng số tiền phải nộp:',
                              tongSoTienPhaiNop.toStringAsFixed(0) + ' ₫'),
                          SizedBox(height: 8),
                          _buildRichText('Tổng số tiền đã nộp:',
                              tongSoTienDaNop.toStringAsFixed(0) + ' ₫'),
                          SizedBox(height: 8),
                          _buildRichText('Số tiền thừa/thiếu:',
                              tongThuaThieu.toStringAsFixed(0) + ' ₫'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Display data grouped by academic year
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: years.length,
                    itemBuilder: (context, index) {
                      String year = years[index];
                      List<Map<String, String>> yearData = groupedData[year]!;
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Năm học: $year',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              Column(
                                children: yearData.map((data) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Học kỳ: ${data['hocKy'] ?? 'N/A'}'),
                                      Text(
                                          'Mức học phí: ${data['mucHocPhi'] ?? 'N/A'} ₫'),
                                      Text(
                                          'Miễn giảm: ${data['mienGiam'] ?? 'N/A'} ₫'),
                                      Text(
                                          'Số tiền phải nộp: ${data['soTienPhaiNop'] ?? 'N/A'} ₫'),
                                      Text(
                                          'Số tiền đã nộp: ${data['soTienDaNop'] ?? 'N/A'} ₫'),
                                      Text(
                                          'Thừa thiếu: ${data['thuaThieu'] ?? 'N/A'} ₫'),
                                      SizedBox(height: 10),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  RichText _buildRichText(String title, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: title, style: TextStyle(fontSize: 14)),
          TextSpan(
              text: ' $value',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;

  const Indicator({
    Key? key,
    required this.color,
    required this.text,
    this.isSquare = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: isSquare ? 16 : 12,
          height: isSquare ? 16 : 12,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
