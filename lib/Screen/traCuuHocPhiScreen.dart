import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import '../include/cookie_provider.dart';
import '../include/config.dart'; // File config chứa baseUrl
import 'loginScreen.dart'; // Thêm đường dẫn đến file đăng nhập
import 'package:shared_preferences/shared_preferences.dart';

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

    // Lấy dữ liệu bảng
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
    double tongSoTienPhaiNop = _calculateTotal(_hocPhiData, 'soTienPhaiNop');
    double tongSoTienDaNop = _calculateTotal(_hocPhiData, 'soTienDaNop');
    double tongThuaThieu = _calculateTotal(_hocPhiData, 'thuaThieu');

    return Scaffold(
      appBar: AppBar(
        title: Text('Tra Cứu Học Phí'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Hiển thị thông tin tổng số tiền dưới dạng Card
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
                              tongSoTienPhaiNop.toStringAsFixed(0) + ' ₫',
                              textColor: Colors.black),
                          SizedBox(height: 8),
                          _buildRichText('Tổng số tiền đã nộp:',
                              tongSoTienDaNop.toStringAsFixed(0) + ' ₫',
                              textColor: Colors.black),
                          SizedBox(height: 8),
                          _buildRichText('Số tiền thừa/thiếu:',
                              tongThuaThieu.toStringAsFixed(0) + ' ₫',
                              textColor: Colors.black),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Hiển thị dữ liệu bảng dưới dạng Card
                  for (var item in _hocPhiData)
                    if (item.containsKey('error'))
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(item['error']!,
                            style: TextStyle(color: Colors.red)),
                      )
                    else if (item.containsKey('hocKy'))
                      Card(
                        margin: EdgeInsets.all(8.0),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.lightBlueAccent,
                                Colors.blueAccent
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8.0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Năm học: ${item['namHoc'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Học kỳ: ${item['hocKy'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.0),
                              _buildRichText(
                                  'Mức học phí:', item['mucHocPhi'] ?? '0',
                                  textColor: Colors.white),
                              _buildRichText(
                                  'Miễn giảm:', item['mienGiam'] ?? '0',
                                  textColor: Colors.white),
                              _buildRichText('Số tiền phải nộp:',
                                  item['soTienPhaiNop'] ?? '0',
                                  textColor: Colors.white),
                              _buildRichText(
                                  'Số tiền đã nộp:', item['soTienDaNop'] ?? '0',
                                  textColor: Colors.white),
                              _buildRichText(
                                  'Thừa/Thiếu:', item['thuaThieu'] ?? '0',
                                  textColor: Colors.red),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }

  RichText _buildRichText(String title, String value,
      {Color textColor = Colors.black}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
              text: title, style: TextStyle(fontSize: 16, color: textColor)),
          TextSpan(
              text: ' $value',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}
