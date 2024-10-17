import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:xml/xml.dart';
import 'package:provider/provider.dart';
import 'package:http/io_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hpc_students/include/theme_provider.dart';
import 'package:hpc_students/include/cookie_provider.dart';
import 'package:hpc_students/include/config.dart';
import 'package:hpc_students/Screen/Blog/blogDetailScreen.dart';
import 'package:hpc_students/Screen/Blog/blogScreen.dart';
import 'package:hpc_students/Screen/loginScreen.dart';
import 'package:hpc_students/Screen/home/category_grid.dart';
import 'blog_service.dart'; // Import the new blog logic file
import 'data_service.dart'; // Import the new data service
import 'firebase_service.dart'; // Import the new Firebase service
import 'schedule_card.dart'; // Import the new schedule card

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
  late BlogService blogService; // Declare BlogService instance as late
  late DataService dataService; // Declare DataService instance
  late FirebaseService firebaseService; // Declare FirebaseService instance

  @override
  void initState() {
    super.initState();
    dataService = DataService(); // Initialize DataService
    firebaseService = FirebaseService(); // Initialize FirebaseService
    blogService = BlogService(blogID); // Initialize BlogService with blogID
    _loadCachedData(); // Load dữ liệu từ cache
    _loadCachedBlogPosts(); // Load cached blog posts
  }

  // Load dữ liệu từ SharedPreferences
  Future<void> _loadCachedData() async {
    print("Loading cached data..."); // Debug print
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
    print("Loaded hoTen: $_hoTen"); // Debug print

    if (_hoTen.isEmpty) {
      print("No cached data found, fetching from server..."); // Debug print
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

    dataService.fetchData(cookie, (data) {
      setState(() {
        _maSinhVien = data['maSinhVien']!;
        _hoTen = data['hoTen']!;
        _trangThai = data['trangThai']!;
        _tinChiTichLuy = data['tinChiTichLuy']!;
        _tbcTichLuy = data['tbcTichLuy']!;
        _xepLoaiHT = data['xepLoaiHT']!;
        _isLoading = false;
        _saveOrUpdateToFirestore(); // Call the new method to save/update Firestore
        _cacheData();
      });
    }, (error) {
      _showSnackBar(error);
      setState(() {
        _isLoading = false;
      });
    });
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
    await blogService.loadBlogPosts(); // Call the method from BlogService
    setState(() {
      _blogPosts = blogService.blogPosts; // Update the blog posts list
    });
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
    await dataService.saveOrUpdateToFirestore(
        _maSinhVien, _hoTen, _trangThai, _tbcTichLuy);
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10),
              Container(
                width: double.infinity, // Đảm bảo Card chiếm toàn bộ chiều rộng
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

              ScheduleCard(), // Display the schedule card

              SizedBox(height: 20),
              // Danh mục
              CategoryGrid(maSinhVien: _maSinhVien), // Pass maSinhVien
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
                          color: Color(0xFF2d59a4),
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
                                  width: 350, // Chiều rộng cố định cho mỗi Card
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
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
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            // Ảnh nằm bên trái
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: Image.network(
                                                _blogPosts[index]['image'] ??
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
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    _blogPosts[index]['title']!
                                                                .length >
                                                            50
                                                        ? _blogPosts[index]
                                                                    ['title']!
                                                                .substring(
                                                                    0, 50) +
                                                            '...'
                                                        : _blogPosts[index]
                                                            ['title']!,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    _blogPosts[index][
                                                                    'category']!
                                                                .length >
                                                            50
                                                        ? _blogPosts[index][
                                                                    'category']!
                                                                .substring(
                                                                    0, 50) +
                                                            '...'
                                                        : _blogPosts[index]
                                                            ['category']!,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
