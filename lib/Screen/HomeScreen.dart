import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:html/parser.dart' as htmlParser;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../include/cookie_provider.dart';
import '../include/config.dart';
import 'Blog/blogDetailScreen.dart';
import 'loginScreen.dart';
import 'package:hpc_students/Screen/Blog/blogScreen.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thư viện SharedPreferences

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _hoTen = '';
  String _trangThai = '';
  String _maSinhVien = '';
  String _tinChiTichLuy = '';
  String _tbcTichLuy = '';
  String _xepLoaiHT = '';
  bool _isLoading = true;
  List<Map<String, String>> _blogPosts = [];

  @override
  void initState() {
    super.initState();
    _loadCachedData(); // Load dữ liệu từ cache
    _fetchBlogPosts(); // Lấy tin tức từ Blogger
  }

  // Load dữ liệu từ SharedPreferences
  Future<void> _loadCachedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hoTen = prefs.getString('hoTen') ?? '';
      _trangThai = prefs.getString('trangThai') ?? '';
      _maSinhVien = prefs.getString('maSinhVien') ?? '';
      _tinChiTichLuy = prefs.getString('tinChiTichLuy') ?? '';
      _tbcTichLuy = prefs.getString('tbcTichLuy') ?? '';
      _xepLoaiHT = prefs.getString('xepLoaiHT') ?? '';
      _isLoading =
          _hoTen.isEmpty; // Nếu không có dữ liệu thì sẽ hiển thị loading
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

          // Lưu hoặc cập nhật thông tin lên Firestore
          _saveOrUpdateToFirestore();

          // Lưu dữ liệu vào SharedPreferences
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
    await _fetchData();
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

  Future<void> _fetchBlogPosts() async {
    var _postsPerPage = 6;
    String url =
        'https://www.blogger.com/feeds/$blogID/posts/default?max-results=$_postsPerPage';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final xmlData = response.body;
        parseXML(xmlData);
      } else {
        print('Lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('Có lỗi xảy ra: $e');
    }
  }

  void parseXML(String xmlString) {
    final document = XmlDocument.parse(xmlString);
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

      // Ensure selfLink is not null before adding it to the post data
      if (selfLink != null) {
        tempPosts.add({
          'title': title,
          'published': published,
          'category': category ?? "Mới",
          'self': selfLink, // Add selfLink to the post data
        });
      }
    }

    setState(() {
      _blogPosts = tempPosts; // Cập nhật danh sách bài viết
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trang Chủ'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData, // Thao tác kéo để làm mới
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
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
                              'TBC tích luỹ $_tbcTichLuy Xếp loại $_xepLoaiHT',
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
                              'Tín chỉ tích luỹ $_tinChiTichLuy',
                              style: TextStyle(
                                fontSize: 16, // Giảm kích thước font
                              ),
                            ),
                            Text(
                              'Trạng thái: $_trangThai',
                              style: TextStyle(
                                fontSize: 16, // Giảm kích thước font
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Tin tức',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Sử dụng GridView để hiển thị tin tức
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Số cột
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
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
                                  Text(
                                    _blogPosts[index]['title']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Expanded(
                                    child: Text(
                                      _blogPosts[index]['published']!,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _blogPosts[index]['category']!,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
