import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hpc_students/Screen/traCuuHocPhiScreen.dart';
import 'package:hpc_students/Screen/traCuuLichHocScreen.dart';
import 'package:hpc_students/Screen/TraCuuDiemRenLuyenScreen.dart';
import 'Screen/profile.dart';
import 'include/config.dart'; // File config chứa baseUrl
import 'package:provider/provider.dart';
import 'include/cookie_provider.dart'; // Import CookieProvider
import 'package:hpc_students/Screen/loginScreen.dart'; // Đường dẫn đến màn hình đăng nhập
import 'package:hpc_students/Screen/TraCuuDiemRenLuyenScreen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Thư viện SharedPreferences
import 'package:hpc_students/Screen/Blog/blogScreen.dart';

void main() {
  setupHttpOverrides();
  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          CookieProvider(), // Cung cấp CookieProvider cho toàn bộ ứng dụng
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkLoginStatus(), // Hàm kiểm tra trạng thái đăng nhập
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            title: 'HPC Students',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: Scaffold(
                body: Center(
                    child: CircularProgressIndicator())), // Hiển thị loading
          );
        } else {
          return MaterialApp(
            title: 'HPC Students',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: LoginScreen(), // Mặc định là màn hình đăng nhập
          );
        }
      },
    );
  }

  Future<bool> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');
    // Kiểm tra nếu cả tên đăng nhập và mật khẩu đều tồn tại
    return username != null && password != null;
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Chỉ số màn hình đang chọn

  // Danh sách các màn hình
  final List<Widget> _screens = [
    HomeScreen(), // Màn hình trang chủ
    TraCuuLichHocScreen(), // Màn hình lịch học
    TraCuuDiemRenLuyenScreen(), // Màn hình điểm rèn luyện
    TraCuuHocPhiScreen(), // Màn hình học phí
    ProfileScreen(), // Màn hình profile
  ];

  Future<void> _logout(BuildContext context) async {
    // URL API đăng xuất
    String url = '$baseUrl/DangNhap/Logout';

    // Lấy cookie từ CookieProvider
    String cookie =
        Provider.of<CookieProvider>(context, listen: false).cookie ?? '';

    // Gửi yêu cầu GET đến API đăng xuất
    try {
      var response = await http.get(
        Uri.parse(url),
        headers: {'Cookie': cookie}, // Sử dụng cookie từ Provider
      );
      if (response.statusCode == 200) {
        // Xóa thông tin đăng nhập từ SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('username'); // Xóa tên đăng nhập
        await prefs.remove('password'); // Xóa mật khẩu

        // Chuyển về màn hình đăng nhập
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        // Xử lý lỗi khi không thể đăng xuất
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi khi đăng xuất: ${response.reasonPhrase}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kiểm tra kết nối Internet!')),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 5) {
      // Đăng xuất là item thứ 6
      _showLogoutConfirmationDialog(
          context); // Gọi phương thức hiển thị dialog xác nhận
    } else {
      setState(() {
        _selectedIndex = index; // Cập nhật chỉ số màn hình
      });
    }
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
                Navigator.of(context).pop(); // Đóng dialog nếu nhấn "Không"
              },
              child: Text('Không'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                _logout(context); // Gọi phương thức đăng xuất
              },
              child: Text('Có'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Hiển thị màn hình tương ứng
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), // Biểu tượng lịch học
            label: 'Lịch học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grade), // Biểu tượng điểm rèn luyện
            label: 'Điểm rèn luyện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on), // Biểu tượng học phí
            label: 'Học phí',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle), // Biểu tượng hồ sơ
            label: 'Hồ sơ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout), // Biểu tượng đăng xuất
            label: 'Đăng xuất',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey, // Màu cho item không được chọn
        onTap: _onItemTapped, // Gọi hàm khi nhấn vào nút
      ),
    );
  }
}

// Màn hình trang chủ
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chủ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('dev by copecute'),
            SizedBox(height: 20), // Khoảng cách giữa văn bản và nút
            ElevatedButton(
              onPressed: () {
                // Khi nhấn nút, điều hướng đến BlogScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BlogScreen()),
                );
              },
              child: Text('Blog'), // Nút "Blog"
            ),
          ],
        ),
      ),
    );
  }
}

// Để bỏ qua chứng chỉ SSL
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
