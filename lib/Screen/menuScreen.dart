import 'package:flutter/material.dart';
import 'package:hpc_students/Screen/Blog/blogScreen.dart';
import 'package:hpc_students/Screen/timNguoiYeu/chat.dart';
import 'package:hpc_students/Screen/traCuuHocPhiScreen.dart';
import 'package:hpc_students/Screen/traCuuLichHocScreen.dart';
import 'package:hpc_students/Screen/rankScreen.dart';
import 'package:hpc_students/Screen/traDiemScreen.dart';
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
import '../include/theme_provider.dart'; // Import ThemeProvider

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _hoTen = '';
  String _dienThoai = '';
  String _ngaySinh = '';
  String _gioiTinh = 'Nam';
  String _truongTHPT = '';
  String _cmnd = '';
  bool _isLoading = true;
  String? _avatarUrl; // Add this line to declare the avatar URL variable
  bool _isFetched = false;

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
      'label': 'HPC Confession',
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
      'label': 'Bài viết',
      'color': Colors.blueGrey
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData().then((_) {
      _fetchData(); // Call the fetchData method after loadData completes
    });
  }

  Future<void> _loadData() async {
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
          _dienThoai = document
                  .getElementById("Dienthoai_canhan")
                  ?.attributes['value'] ??
              '';
          _ngaySinh =
              document.getElementById("Ngay_sinh")?.attributes['value'] ?? '';
          _gioiTinh = document
                  .getElementById("ID_gioi_tinh")
                  ?.querySelector('option[selected]')
                  ?.text ??
              'Nam';
          _truongTHPT =
              document.getElementById("TruongTHPT")?.attributes['value'] ?? '';
          _cmnd = document.getElementById("CMND")?.attributes['value'] ?? '';
          _isLoading = false;
        });

        // Gọi phương thức fetchData để lấy avatar
        _fetchData();
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

    final url = 'https://zalo.me/$_dienThoai';
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    final ioClient = IOClient(httpClient);

    try {
      final response = await ioClient.get(
        Uri.parse(url),
      );

      if (response.statusCode == 200) {
        print("đã get $url");
        String responseBody = response.body;

        // Extract the avatar URL from the response body
        RegExp regExp = RegExp(r'"avatar":"(.*?)"');
        Match? match = regExp.firstMatch(responseBody);
        String avatarUrl = match != null ? match.group(1) ?? '' : '';

        // Nếu không có avatarUrl hoặc trống thì sử dụng ảnh cục bộ
        setState(() {
          _avatarUrl = avatarUrl.isNotEmpty
              ? avatarUrl
              : null; // Dùng null để kiểm tra trong UI
          _isLoading = false; // Set loading to false
          _isFetched = true; // Mark data as fetched
        });
        print("đã get $avatarUrl");
        // Lưu thông tin vào SharedPreferences sau khi đã lấy xong avatar
        _saveUserData();
      } else {
        setState(() {
          _avatarUrl = null;
          _isLoading = false; // Set loading to false
          _isFetched = true; // Mark data as fetched
        });
      }
    } catch (e) {
      setState(() {
        _avatarUrl = null;
        _isLoading = false; // Set loading to false
        _isFetched = true; // Mark data as fetched
      });
    } finally {
      ioClient.close();
    }
  }

  Future<void> _saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('hoTen', _hoTen);
    await prefs.setString('dienThoai', _dienThoai);
    await prefs.setString('ngaySinh', _ngaySinh);
    await prefs.setString('gioiTinh', _gioiTinh);
    await prefs.setString('truongTHPT', _truongTHPT);
    await prefs.setString('cmnd', _cmnd);
    await prefs.setString('avatarUrl', _avatarUrl ?? ''); // Lưu avatar URL
    print("avatar: ${prefs.getString('avatarUrl')}");
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Get the theme provider

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hồ sơ',
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Card hiển thị thông tin profile (fixed)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(),
                      ),
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
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : AssetImage(
                                    'assets/avatar.png'), // Use fetched avatar or local image
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_hoTen',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Xem chi tiết hồ sơ',
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
                await prefs.clear(); // Clear all cached data on logout
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
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TraDiemScreen()),
        );
        break;
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
              builder: (context) => ChatScreen(
                username: username,
              ),
            ),
          );
        } else {
          // Handle case where username is not found
          _showSnackBar(context, 'Tên người dùng không tồn tại.');
        }
        break;
      case 8:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RankScreen()),
        );
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
          throw 'Không thể mở CLUB Thịt Chó Bách Khoa';
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
