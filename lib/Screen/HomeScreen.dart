import 'dart:io';
import 'package:hpc_students/Screen/yeuCau/traCuuYeuCau.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:xml/xml.dart';
import 'package:provider/provider.dart';
import 'package:http/io_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hpc_students/Screen/TraCuuDiemRenLuyenScreen.dart';
import 'package:hpc_students/Screen/menu/menuScreen.dart';
import 'package:hpc_students/Screen/rankScreen.dart';
import 'package:hpc_students/Screen/timNguoiYeu/chat.dart';
import 'package:hpc_students/Screen/traCuuHocPhiScreen.dart';
import 'package:hpc_students/Screen/traCuuLichHocScreen.dart';
import 'package:hpc_students/Screen/traDiemScreen.dart';
import 'package:hpc_students/include/theme_provider.dart';
import 'package:hpc_students/include/cookie_provider.dart';
import 'package:hpc_students/include/config.dart';
import 'package:hpc_students/Screen/Blog/blogDetailScreen.dart';
import 'package:hpc_students/Screen/Blog/blogScreen.dart';
import 'package:hpc_students/Screen/loginScreen.dart';
import 'package:hpc_students/Screen/menu/navigation_service.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _hoTen = '';
  String _trangThai = '';
  String _maSinhVien = '';
  String _tinChiTichLuy = '';
  String _tbcTichLuy = '0';
  String _xepLoaiHT = '';
  bool _isLoading = true;
  List<Map<String, String>> _blogPosts = [];
  double _tbcTichLuyValue = 0.0; // Variable to hold the TBC value
  double _maxTbcValue = 10.0; // Maximum TBC value for comparison
  String _defaultImage =
      'https://blogger.googleusercontent.com/img/a/AVvXsEiYorgTwvKTp7bjT_1O6HrAl2K4vYEcimlyzfv-0UNwF8x_ov7avCHuZoVdg6K-u2GhL7bOUOmL9DSC4YiBQOF82bmOxYFhmzcd_S15-AikwfL83vmYIAPuBtCPGeRsRfAiVw0REdGk-GZltwNDSWuKC-WFGvU1WwUCASD8CynnsGpOH91geRjUW2rVmC0=w220-h146-p-k-no-nu'; // Default image URL
  List<Map<String, String>> _cachedBlogPosts =
      []; // Variable to hold cached blog posts
  bool _hasFetchedData = false; // Flag to check if data has been fetched

  @override
  void initState() {
    super.initState();
    _loadCachedData(); // Load dữ liệu từ cache
    _loadCachedBlogPosts(); // Load cached blog posts
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
        _showSnackBar('Không có kết nối internet. Vui lòng kiểm tra lại.');
        print('Failed to fetch data. Status code: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } on SocketException catch (_) {
      _showSnackBar('Không có kết nối internet. Vui lòng kiểm tra lại.');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar('Không có kết nối internet. Vui lòng kiểm tra lại.');
      print('An error occurred while fetching data: $e');
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

  // Load cached blog posts from SharedPreferences
  Future<void> _loadCachedBlogPosts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedPosts = prefs.getString('cachedBlogPosts');
    if (cachedPosts != null) {
      setState(() {
        // Check if the cached data is XML or JSON
        if (cachedPosts.trim().startsWith('<')) {
          // Handle XML data
          _blogPosts =
              _parseXmlData(cachedPosts); // Call a new method to parse XML
        } else {
          // Handle JSON data
          _blogPosts = List<Map<String, String>>.from(json
              .decode(cachedPosts)
              .map((post) => Map<String, String>.from(post)));
        }
        _hasFetchedData =
            true; // Set the flag to true if cached data is available
      });
    } else {
      // If no cached data, fetch from the server
      _fetchBlogPosts();
    }
  }

  // Fetch blog posts similar to BlogScreen.dart
  Future<void> _fetchBlogPosts() async {
    if (_hasFetchedData)
      return; // Prevent fetching if data has already been fetched

    setState(() {
      _isLoading = true; // Set loading state
    });

    String url =
        'https://www.blogger.com/feeds/$blogID/posts/default?max-results=5';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Parse the XML response
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
              .getAttribute('term');

          final selfLink = entry
              .findElements('link')
              .firstWhere(
                (link) => link.getAttribute('rel') == 'self',
                orElse: () => XmlElement(XmlName('link')),
              )
              .getAttribute('href');

          // Use the new _getThumbnail method to extract the image URL
          final imageUrl = _getThumbnail(entry);

          // Ensure selfLink is not null before adding it to the post data
          if (selfLink != null) {
            tempPosts.add({
              'title': title,
              'published': published,
              'category': category ?? "Mới",
              'self': selfLink,
              'image': imageUrl ?? _defaultImage,
            });
          }
        }

        // Cache the fetched blog posts in JSON format
        await _cacheBlogPosts(tempPosts);

        setState(() {
          _blogPosts = tempPosts; // Update the blog posts list
          _isLoading = false; // Reset loading state
          _hasFetchedData = true; // Set the flag to true after fetching
        });
      } else {
        _showSnackBar('Không có kết nối internet. Vui lòng kiểm tra lại.');
        print('Error: ${response.statusCode}');
        setState(() {
          _isLoading = false; // Reset loading state on error
        });
      }
    } catch (e) {
      _showSnackBar('Không có kết nối internet. Vui lòng kiểm tra lại.');
      print('Error fetching blog posts: $e');
      setState(() {
        _isLoading = false; // Reset loading state on exception
      });
    }
  }

  // Cache the blog posts to SharedPreferences
  Future<void> _cacheBlogPosts(List<Map<String, String>> posts) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedPosts = json.encode(posts);
    await prefs.setString('cachedBlogPosts', encodedPosts);
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

  // Define the _buildCategoryItem method
  Widget _buildCategoryItem(IconData icon, String title) {
    return Material(
      borderRadius: BorderRadius.circular(12), // Rounded corners
      elevation: 4, // Shadow effect
      child: InkWell(
        borderRadius: BorderRadius.circular(12), // Match the border radius
        onTap: () {
          // Handle tap action using switch case
          switch (title) {
            case 'Thời khoá biểu':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TraCuuLichHocScreen()),
              );
              break;
            case 'Kết quả học tập':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TraDiemScreen()),
              );
              break;
            case 'Học phí':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TraCuuHocPhiScreen()),
              );
              break;
            case 'Điểm rèn luyện':
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TraCuuDiemRenLuyenScreen()),
              );
              break;
            case 'Tìm người yêu':
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatScreen(username: _maSinhVien)),
              );
              print("vào chat với username $_maSinhVien");
              break;
            case 'HPC Ranking':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RankScreen()),
              );
              break;
            case 'Quản lý yêu cầu':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TraCuuYeuCauScreen()),
              );
              break;
            case 'Tất cả':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MenuScreen()),
              );
              break;
            default:
              showSnackBar(context, 'Chưa có chức năng này!');
          }
        },
        child: Container(
          padding: EdgeInsets.all(0), // Reduced padding inside the container
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 30, color: Color(0xFF2d59a4)), // Reduced icon size
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

  void _showSnackBar(String message) {
    if (mounted) {
      // Kiểm tra xem widget có còn tồn tại không
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // New method to parse XML data
  List<Map<String, String>> _parseXmlData(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    List<Map<String, String>> posts = [];
    final entries =
        document.findAllElements('entry'); // Adjust based on your XML structure

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
          .getAttribute('term');

      final selfLink = entry
          .findElements('link')
          .firstWhere(
            (link) => link.getAttribute('rel') == 'self',
            orElse: () => XmlElement(XmlName('link')),
          )
          .getAttribute('href');

      // Use the new _getThumbnail method to extract the image URL
      final imageUrl = _getThumbnail(entry);

      // Ensure selfLink is not null before adding it to the post data
      if (selfLink != null) {
        posts.add({
          'title': title,
          'published': published,
          'category': category ?? "Mới",
          'self': selfLink,
          'image': imageUrl ?? _defaultImage,
        });
      }
    }
    return posts; // Return the parsed posts
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Get the theme provider

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Xin chào! $_hoTen',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2d59a4),
        actions: [
          PopupMenuButton<ThemeMode>(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.wb_sunny // Sun icon for light theme
                  : Icons.nights_stay, // Moon icon for dark theme
            ),
            onSelected: (ThemeMode newValue) {
              themeProvider.toggleTheme(newValue);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: ThemeMode.light,
                child: Text('Sáng'),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Text('Tối'),
              ),
              PopupMenuItem(
                value: ThemeMode.system,
                child: Text('Hệ thống'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData, // Thao tác kéo để làm mới
        child: _isLoading
            ? Center(child: CircularProgressIndicator()) // Hiển thị loading
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Container(
                      width: double
                          .infinity, // Đảm bảo Card chiếm toàn bộ chiều rộng
                      child: Card(
                        margin: EdgeInsets.all(0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              SizedBox(height: 5),
                              Text(
                                'TBC tích lũy $_tbcTichLuy, Xếp loại $_xepLoaiHT',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Tín chỉ tích lũy $_tinChiTichLuy',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                    // Danh mục
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        // 4 mục trong một dòng
                        crossAxisSpacing: 8,
                        // Khoảng cách giữa các cột
                        mainAxisSpacing: 8,
                        // Khoảng cách giữa các hàng
                        children: [
                          _buildCategoryItem(
                              Icons.calendar_today, 'Thời khoá biểu'),
                          _buildCategoryItem(
                              Icons.add_chart, 'Kết quả học tập'),
                          _buildCategoryItem(Icons.monetization_on, 'Học phí'),
                          _buildCategoryItem(Icons.score, 'Điểm rèn luyện'),
                          _buildCategoryItem(Icons.favorite, 'Tìm người yêu'),
                          _buildCategoryItem(Icons.stars, 'HPC Ranking'),
                          _buildCategoryItem(
                              Icons.mark_email_unread_sharp, 'Quản lý yêu cầu'),
                          _buildCategoryItem(Icons.grid_view, 'Tất cả'),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Tin tức section
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
                                  builder: (context) => BlogScreen(),
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

                    // Check if blog posts are loading
                    _blogPosts.isEmpty && !_isLoading
                        ? Center(child: CircularProgressIndicator())
                        : Container(
                            height: 150, // Chiều cao cố định cho phần tin tức
                            child: _isLoading
                                ? Center(
                                    child:
                                        CircularProgressIndicator()) // Hiển thị loading khi dữ liệu đang được tải
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _blogPosts.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        width:
                                            350, // Chiều rộng cố định cho mỗi Card
                                        margin:
                                            EdgeInsets.symmetric(horizontal: 8),
                                        child: Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      BlogDetailScreen(
                                                    postUrl: _blogPosts[index]
                                                        ['self']!,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Row(
                                                children: [
                                                  // Ảnh nằm bên trái
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    child: Image.network(
                                                      _blogPosts[index]
                                                              ['image'] ??
                                                          '',
                                                      width:
                                                          120, // Kích thước chiều rộng cố định
                                                      height:
                                                          120, // Kích thước chiều cao cố định
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  // Khoảng cách giữa ảnh và text
                                                  // Tiêu đề nằm bên phải
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          _blogPosts[index][
                                                                          'title']!
                                                                      .length >
                                                                  50
                                                              ? _blogPosts[index]
                                                                          [
                                                                          'title']!
                                                                      .substring(
                                                                          0,
                                                                          50) +
                                                                  '...'
                                                              : _blogPosts[
                                                                      index]
                                                                  ['title']!,
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        Text(
                                                          _blogPosts[index][
                                                                          'category']!
                                                                      .length >
                                                                  50
                                                              ? _blogPosts[index]
                                                                          [
                                                                          'category']!
                                                                      .substring(
                                                                          0,
                                                                          50) +
                                                                  '...'
                                                              : _blogPosts[
                                                                      index]
                                                                  ['category']!,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
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
