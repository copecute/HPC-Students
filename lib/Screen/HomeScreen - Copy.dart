import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:html/parser.dart' as htmlParser;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../include/cookie_provider.dart';
import '../include/config.dart';
import 'Blog/blogDetailScreen.dart';
import 'Blog/blogScreen.dart'; // Import BlogScreen
import 'loginScreen.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thư viện SharedPreferences
import 'package:fl_chart/fl_chart.dart'; // Import the fl_chart package

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _hoTen = '';
  String _trangThai = '';
  String _maSinhVien = '';
  String _tinChiTichLuy = '';
  String _tbcTichLuy = '0'; // Set TBC tích lũy to 7.1
  String _xepLoaiHT = '';
  bool _isLoading = true;
  List<Map<String, String>> _blogPosts = [];
  double _tbcTichLuyValue = 0.0; // Variable to hold the TBC value
  double _maxTbcValue = 10.0; // Maximum TBC value for comparison
  String _defaultImage =
      'https://blogger.googleusercontent.com/img/a/AVvXsEiYorgTwvKTp7bjT_1O6HrAl2K4vYEcimlyzfv-0UNwF8x_ov7avCHuZoVdg6K-u2GhL7bOUOmL9DSC4YiBQOF82bmOxYFhmzcd_S15-AikwfL83vmYIAPuBtCPGeRsRfAiVw0REdGk-GZltwNDSWuKC-WFGvU1WwUCASD8CynnsGpOH91geRjUW2rVmC0=w220-h146-p-k-no-nu'; // Default image URL

  @override
  void initState() {
    super.initState();
    _loadCachedData(); // Load dữ liệu từ cache
    _fetchBlogPosts(); // Fetch blog posts on initialization
  }

  // Load dữ liệu từ SharedPreferences
  Future<void> _loadCachedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hoTen = prefs.getString('hoTen') ?? '';
      _trangThai = prefs.getString('trangThai') ?? '';
      _maSinhVien = prefs.getString('maSinhVien') ?? '';
      _tinChiTichLuy = prefs.getString('tinChiTichLuy') ?? '0';
      _tbcTichLuy = prefs.getString('tbcTichLuy') ?? '0';
      _xepLoaiHT = prefs.getString('xepLoaiHT') ?? '';
      _isLoading =
          _hoTen.isEmpty; // Nếu không có dữ liệu thì sẽ hiển thị loading

      // Parse TBC value
      _tbcTichLuyValue =
          double.tryParse(_tbcTichLuy) ?? 0.0; // Parse TBC tích lũy
    });

    if (_hoTen.isEmpty) {
      _fetchData(); // Nếu không có dữ liệu, tải từ server
    }
  }

  // Hàm fetchData sẽ chỉ được gọi khi refresh hoặc không có dữ liệu trong cache
  Future<void> _fetchData() async {
    String? cookie =
        Provider.of<CookieProvider>(context, listen: false).getCookie();

    if (cookie == null || cookie.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      return;
    }

    final url = '$baseUrl/TraCuuDiem/Index';
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    final ioClient = IOClient(httpClient);

    try {
      final response = await ioClient.get(
        Uri.parse(url),
        headers: {
          'Cookie': cookie,
        },
      );

      if (response.statusCode == 200) {
        var document = htmlParser.parse(response.body);
        setState(() {
          _maSinhVien = document.getElementById("MaSinhVien")?.text.trim() ??
              'Không tìm thấy mã sinh viên';
          var hoTenVaTrangThai = document
              .querySelector("a.dropdown .styMenu")
              ?.innerHtml
              .trim()
              .split('<br>');
          _hoTen = hoTenVaTrangThai?[0].trim() ?? 'Không tìm thấy tên';
          _trangThai =
              hoTenVaTrangThai?[1].trim() ?? 'Không tìm thấy trạng thái';
          _tinChiTichLuy =
              document.getElementById("TinChiTichLuy")?.text.trim() ??
                  'Không tìm thấy tín chỉ';
          _tbcTichLuy = document.getElementById("TBCTichLuyH10")?.text.trim() ??
              'Không tìm thấy TBC tích luỹ';
          _xepLoaiHT = document.getElementById("XepLoaiHTH10")?.text.trim() ??
              'Không tìm thấy xếp loại học tập';
          _isLoading = false;
          _saveOrUpdateToFirestore();
          _cacheData();
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    } finally {
      ioClient.close();
    }
  }

  String? _getThumbnail(XmlElement post) {
    final mediaThumbnails = post.findElements('media:thumbnail');
    if (mediaThumbnails.isNotEmpty) {
      return mediaThumbnails.first.getAttribute('url');
    }
    final content = post.findElements('content').first.text;
    final regExp = RegExp(r'<img.*?src="(.*?)"', caseSensitive: false);
    final match = regExp.firstMatch(content);
    if (match != null) {
      return match.group(1);
    }
    return _defaultImage; // Return default image if no thumbnail is found
  }

  // Fetch blog posts similar to BlogScreen.dart
  Future<void> _fetchBlogPosts() async {
    setState(() {
      _isLoading = true; // Set loading state
    });

    String url = 'https://www.blogger.com/feeds/$blogID/posts/default';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final entries = document.findAllElements('entry');

        List<Map<String, String>> tempPosts = [];
        for (var entry in entries) {
          final title = entry.findElements('title').single.text;
          final published = entry.findElements('published').single.text;
          final category = entry
              .findElements('category')
              .firstWhere(
                (link) =>
                    link.getAttribute('scheme') ==
                    'http://www.blogger.com/atom/ns#',
                orElse: () => XmlElement(XmlName('category')),
              )
              .getAttribute('term'); // Get the category

          final selfLink = entry
              .findElements('link')
              .firstWhere(
                (link) => link.getAttribute('rel') == 'self',
                orElse: () => XmlElement(XmlName('link')),
              )
              .getAttribute('href'); // Get the selfLink

          // Use the new _getThumbnail method to extract the image URL
          final imageUrl = _getThumbnail(entry);

          // Ensure selfLink is not null before adding it to the post data
          if (selfLink != null) {
            tempPosts.add({
              'title': title,
              'published': published,
              'category': category ?? "Mới",
              'self': selfLink, // Add selfLink to the post data
              'image':
                  imageUrl ?? _defaultImage, // Use the new method for image URL
            });
          }
        }

        setState(() {
          _blogPosts = tempPosts; // Update the blog posts list
          _isLoading = false; // Reset loading state
        });
      } else {
        print('Error: ${response.statusCode}');
        setState(() {
          _isLoading = false; // Reset loading state on error
        });
      }
    } catch (e) {
      print('Error fetching blog posts: $e');
      setState(() {
        _isLoading = false; // Reset loading state on exception
      });
    }
  }

  // Lưu dữ liệu vào SharedPreferences
  Future<void> _cacheData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('hoTen', _hoTen);
    await prefs.setString('trangThai', _trangThai);
    await prefs.setString('maSinhVien', _maSinhVien); // Đảm bảo lưu maSinhVien
    await prefs.setString('tinChiTichLuy', _tinChiTichLuy);
    await prefs.setString('tbcTichLuy', _tbcTichLuy);
    await prefs.setString('xepLoaiHT', _xepLoaiHT);
  }

  // Hàm để làm mới dữ liệu khi kéo xuống
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchData(); // Fetch fresh data from the server
    await _fetchBlogPosts(); // Fetch blog posts again
  }

  Future<void> _saveOrUpdateToFirestore() async {
    CollectionReference students =
        FirebaseFirestore.instance.collection('HPCRanks');

    try {
      DocumentSnapshot doc = await students.doc(_maSinhVien).get();
      bool isTrangThaiActive = _trangThai.contains("Đang học");

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        bool needsUpdate = false;

        if (data['fullname'] != _hoTen) needsUpdate = true;
        if (data['Trangthai'] != isTrangThaiActive) needsUpdate = true;
        if (data['TBC'] != _tbcTichLuy) needsUpdate = true;

        if (needsUpdate) {
          await students.doc(_maSinhVien).update({
            'fullname': _hoTen,
            'Trangthai': isTrangThaiActive,
            'TBC': _tbcTichLuy,
            'timestamp': FieldValue.serverTimestamp(),
          });

          print('Cập nhật dữ liệu lên Firestore thành công');
        } else {
          print('Dữ liệu đã đúng, không cần cập nhật');
        }
      } else {
        await students.doc(_maSinhVien).set({
          'fullname': _hoTen,
          'Trangthai': isTrangThaiActive,
          'TBC': _tbcTichLuy,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print('Tạo mới và lưu dữ liệu lên Firestore thành công');
      }
    } catch (e) {
      print('Lỗi khi lưu dữ liệu lên Firestore: $e');
    }
  }

  // Sample data for the chart
  List<BarChartGroupData> _getBarChartData() {
    // Split the _tinChiTichLuy string to get accumulated and registered credits
    List<String> credits = _tinChiTichLuy.split(' / ');
    double accumulatedCredits =
        double.tryParse(credits[0]) ?? 0.0; // Parse accumulated credits
    double registeredCredits = credits.length > 1
        ? double.tryParse(credits[1]) ?? 0.0
        : 0.0; // Parse registered credits

    return [
      BarChartGroupData(x: 0, barRods: [
        BarChartRodData(
          toY: accumulatedCredits,
          color: Colors.blue,
          width: 30, // Set the width of the bar
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: registeredCredits, // Background bar for registered credits
            color: Colors.red.withOpacity(0.3), // Background color
          ),
        ),
      ]),
      BarChartGroupData(x: 1, barRods: [
        BarChartRodData(
          toY: registeredCredits,
          color: Colors.red,
          width: 30, // Set the width of the bar
        ),
      ]),
    ];
  }

  // Method to build the bar chart
  Widget _buildBarChart() {
    return Container(
      height: 200, // Set the height of the chart
      child: BarChart(
        BarChartData(
          barGroups: _getBarChartData(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return Text('Tín chỉ tích lũy');
                    case 1:
                      return Text('Tín chỉ đăng ký');
                    default:
                      return Text('');
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              // Use the new way to set the tooltip background color
              tooltipMargin: 8,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String title;
                switch (group.x.toInt()) {
                  case 0:
                    title = 'Tín chỉ tích lũy';
                    break;
                  case 1:
                    title = 'Tín chỉ đăng ký';
                    break;
                  default:
                    title = '';
                }
                return BarTooltipItem(
                  title + '\n',
                  TextStyle(color: Colors.white),
                  children: [
                    TextSpan(
                      text: rod.toY.toString(),
                      style: TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Define the _buildCategoryItem method
  Widget _buildCategoryItem(IconData icon, String title) {
    return Material(
      borderRadius: BorderRadius.circular(12), // Rounded corners
      elevation: 4, // Shadow effect
      child: InkWell(
        borderRadius: BorderRadius.circular(12), // Match the border radius
        onTap: () {
          // Handle tap action here
          print('$title tapped'); // Example action
        },
        child: Container(
          padding: EdgeInsets.all(0), // Reduced padding inside the container
          decoration: BoxDecoration(
            // color: Colors.white, // Background color
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.blue), // Reduced icon size
              SizedBox(height: 6), // Reduced space between icon and text
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold), // Reduced font size
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData, // Thao tác kéo để làm mới
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator()) // Show loading indicator
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Card(
                      margin: EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(height: 10),
                            Text(
                              'Xin chào! $_hoTen',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'TBC tích lũy $_tbcTichLuy Xếp loại $_xepLoaiHT',
                              style: TextStyle(
                                fontSize: 16, // Giảm kích thước font
                              ),
                            ),
                            Text(
                              'Xếp loại học tập $_xepLoaiHT',
                              style: TextStyle(
                                fontSize: 16, // Giảm kích thước font
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Tín chỉ tích lũy $_tinChiTichLuy',
                              style: TextStyle(
                                fontSize: 16, // Giảm kích thước font
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildBarChart(), // Call the bar chart method

                    Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh mục',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BlogScreen(), // Navigate to BlogScreen
                                ),
                              );
                            },
                            child: Text(
                              'Tùy chỉnh >',
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Danh mục section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 0.0, // Reduced top padding to 0
                          horizontal: 10.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount:
                            4, // Change to 4 to fit four buttons in one row
                        crossAxisSpacing: 8, // Adjust spacing between columns
                        mainAxisSpacing: 8, // Adjust spacing between rows
                        children: [
                          _buildCategoryItem(
                              Icons.calendar_today, 'Lịch công tác'),
                          _buildCategoryItem(Icons.notifications, 'Thông báo'),
                          _buildCategoryItem(Icons.mail, 'Hộp thư'),
                          _buildCategoryItem(Icons.contact_mail, 'Liên hệ'),
                          _buildCategoryItem(Icons.work, 'Công việc'),
                          _buildCategoryItem(Icons.folder, 'Tài nguyên'),
                          _buildCategoryItem(Icons.money, 'Xem lương'),
                          _buildCategoryItem(Icons.grid_view, 'Tất cả'),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tin tức',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BlogScreen(), // Navigate to BlogScreen
                                ),
                              );
                            },
                            child: Text(
                              'Xem tất cả >',
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sử dụng ListView để hiển thị tin tức theo chiều ngang
                    Container(
                      height: 200, // Set a fixed height for the news section
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _blogPosts.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 4,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlogDetailScreen(
                                        postUrl: _blogPosts[index]['self']!),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image display for each blog post
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          8.0), // Rounded corners
                                      child: Image.network(
                                        _blogPosts[index]['image'] ?? '',
                                        width:
                                            150, // Set a fixed width for the image
                                        height:
                                            100, // Set a fixed height for the image
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    // Title with a maximum of 2 lines
                                    Text(
                                      _blogPosts[index]['title']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
