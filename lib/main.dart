import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'package:hpc_students/Screen/HomeScreen.dart';
import 'package:hpc_students/Screen/menu/menuScreen.dart';
import 'include/theme_provider.dart'; // Import ThemeProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized
  await Firebase.initializeApp(); // Initialize Firebase
  setupHttpOverrides();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) =>
                CookieProvider()), // Ensure CookieProvider is available
        ChangeNotifierProvider(
            create: (_) =>
                ThemeProvider()), // Ensure ThemeProvider is available
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'HPC Students',
      theme: themeProvider.lightTheme, // Light theme
      darkTheme: themeProvider.darkTheme, // Dark theme
      themeMode: themeProvider.themeMode, // Set the theme mode
      home: FutureBuilder(
        future: _checkLoginStatus(), // Hàm kiểm tra trạng thái đăng nhập
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
                body: Center(
                    child: CircularProgressIndicator())); // Hiển thị loading
          } else {
            return LoginScreen(); // Mặc định là màn hình đăng nhập
          }
        },
      ),
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
    MenuScreen(), // Màn hình menu
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Cập nhật chỉ số màn hình
    });
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
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey, // Màu cho item không được chọn
        onTap: _onItemTapped, // Gọi hàm khi nhấn vào nút
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
