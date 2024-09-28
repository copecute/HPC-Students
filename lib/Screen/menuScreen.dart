import 'package:flutter/material.dart';
import 'package:hpc_students/Screen/Blog/blogScreen.dart';
import 'package:hpc_students/Screen/timNguoiYeu/chat.dart';
import 'package:hpc_students/Screen/traCuuHocPhiScreen.dart';
import 'package:hpc_students/Screen/traCuuLichHocScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:html/parser.dart' as htmlParser;
import '../include/cookie_provider.dart';
import '../include/config.dart';
import 'loginScreen.dart';
import 'profile.dart'; // Import ProfileScreen
import 'package:hpc_students/Screen/timNguoiYeu/chat.dart'; // Import ChatScreen
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Database

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _hoTen = '';
  bool _isLoading = true;
  bool _dataLoaded = false;

  final List<Map<String, dynamic>> buttons = [
    {
      'id': 1,
      'icon': Icons.group,
      'label': 'Danh sách lớp',
      'color': Colors.orange
    },
    {
      'id': 2,
      'icon': Icons.add_chart,
      'label': 'Kết quả học tập',
      'color': Colors.green
    },
    {
      'id': 3,
      'icon': Icons.book,
      'label': 'Mục tiêu tốt nghiệp',
      'color': Colors.red
    },
    {
      'id': 4,
      'icon': Icons.calendar_today,
      'label': 'Thời khoá biểu',
      'color': Colors.blue
    },
    {
      'id': 5,
      'icon': Icons.favorite,
      'label': 'Tìm người yêu',
      'color': Colors.pink
    },
    {
      'id': 6,
      'icon': Icons.alarm,
      'label': 'Báo thức',
      'color': Colors.deepOrange
    },
    {
      'id': 7,
      'icon': Icons.sentiment_dissatisfied,
      'label': 'Kỹ năng mềm',
      'color': Colors.teal
    },
    {
      'id': 8,
      'icon': Icons.stars,
      'label': 'HPC Ranking',
      'color': Colors.indigo
    },
    {
      'id': 9,
      'icon': Icons.monetization_on,
      'label': 'Học phí',
      'color': Colors.brown
    },
    {
      'id': 10,
      'icon': Icons.rate_review,
      'label': 'Review học phần',
      'color': Colors.purple
    },
    {
      'id': 11,
      'icon': Icons.star,
      'label': 'CLUB Thịt Chó Bách Khoa',
      'color': Colors.red
    },
    {
      'id': 12,
      'icon': Icons.newspaper,
      'label': 'Tin tức',
      'color': Colors.blueGrey
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_dataLoaded) {
      await _fetchData();
      _dataLoaded = true;
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

    final url = '$baseUrl/SinhVien/ThongTinSinhVien';
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
          _hoTen = document.getElementById("Ho_ten")?.attributes['value'] ?? '';
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Menu',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2d59a4),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Card hiển thị thông tin profile (fixed)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage('assets/avatar.png'),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Họ và Tên: $_hoTen',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                FutureBuilder<SharedPreferences>(
                                  future: SharedPreferences.getInstance(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final prefs = snapshot.data;
                                      return Text(
                                          'Mã sinh viên: ${prefs?.getString('username') ?? 'Chưa có'}');
                                    }
                                    return Text('Mã sinh viên: Đang tải...');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // GridView hiển thị các chức năng (scrollable)
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(10),
                    itemCount: buttons.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      return _buildGridButton(
                        context,
                        buttons[index]['id'],
                        buttons[index]['icon'],
                        buttons[index]['label'],
                        buttons[index]['color'],
                      );
                    },
                  ),
                ),
                // Nút đăng xuất (fixed)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _showLogoutConfirmationDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2d59a4),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Đăng xuất',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận đăng xuất'),
          content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Không'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('username');
                await prefs.remove('password');
                Navigator.of(context, rootNavigator: true).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Có'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGridButton(
    BuildContext context,
    int id,
    IconData icon,
    String label,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        _handleNavigation(context, id);
      },
      borderRadius: BorderRadius.circular(8),
      splashColor: color.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNavigation(BuildContext context, int id) async {
    switch (id) {
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TraCuuLichHocScreen()),
        );
        break;
      case 5:
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? username =
            prefs.getString('username'); // Get username from SharedPreferences

        if (username != null) {
          // Navigate to ChatScreen and add user to queue
          final DatabaseReference queueRef =
              FirebaseDatabase.instance.ref('queue');
          await queueRef.push().set(username); // Add user to queue

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(username: username,),
            ),
          );
        } else {
          // Handle case where username is not found
          _showSnackBar(context, 'Tên người dùng không tồn tại.');
        }
        break;
      case 9:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TraCuuHocPhiScreen()),
        );
        break;
      case 11:
        final Uri url = Uri.parse('https://zalo.me/g/uttoza177');
        if (!await launchUrl(url)) {
          throw 'Could not launch $url';
        }
        break;
      case 12:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BlogScreen()),
        );
        break;
      default:
        _showSnackBar(context, 'Chưa có chức năng này!');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
