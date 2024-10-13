import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hpc_students/Screen/lichHoc/traCuuLichHocScreen.dart';
import 'package:hpc_students/Screen/traDiemScreen.dart';
import 'include/config.dart';
import 'package:provider/provider.dart';
import 'include/cookie_provider.dart'; // Import CookieProvider
import 'package:hpc_students/Screen/loginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thư viện SharedPreferences
import 'package:hpc_students/Screen/HomeScreen.dart';
import 'package:hpc_students/Screen/menu/menuScreen.dart';
import 'include/theme_provider.dart'; // Import ThemeProvider
import 'package:flutter_localizations/flutter_localizations.dart';

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
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      scaffoldMessengerKey:
          _scaffoldMessengerKey, // Set the key for ScaffoldMessenger
      title: 'HPC Students',
      theme: themeProvider.lightTheme, // Light theme
      darkTheme: themeProvider.darkTheme, // Dark theme
      themeMode: themeProvider.themeMode, // Set the theme mode
      // Locale tự động nhận diện từ ngôn ngữ hệ thống
      locale: WidgetsBinding.instance.window.locale,
      supportedLocales: [
        const Locale('en', 'US'), // Tiếng Anh
        const Locale('vi', 'VN'), // Tiếng Việt
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FutureBuilder(
        future:
            _mockCheckLoginStatus(), // Use a mock future that delays the check
        builder: (context, snapshot) {
          // Directly return LoginScreen after the future completes
          return LoginScreen(); // Default to the login screen after delay
        },
      ),
    );
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Mock function to simulate delay
  Future<bool> _mockCheckLoginStatus() async {
    await Future.delayed(Duration(seconds: 5)); // Simulate a delay
    return _checkLoginStatus(); // Then proceed to check login status
  }

  Future<bool> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');

    if (username != null && password != null) {
      try {
        // Attempt to simulate a network request or check
        return await simulateNetworkRequest(username, password);
      } on SocketException catch (_) {
        // Handle no internet connection
        _showSnackBar('Không có kết nối internet. Vui lòng kiểm tra lại.');
        print('No internet connection available.');
        return false;
      } catch (e) {
        // Handle other exceptions
        print('An error occurred: $e');
        return false;
      }
    }
    return false;
  }

  // Simulated network request for demonstration
  Future<bool> simulateNetworkRequest(String username, String password) async {
    // This is a placeholder for actual network interaction
    await Future.delayed(Duration(seconds: 1)); // Simulate network latency
    return true; // Simulate successful network response
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
    TraDiemScreen(), // Màn hình điểm rèn luyện
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
            icon: Icon(Icons.add_chart), // Biểu tượng điểm rèn luyện
            label: 'Kết quả học tập',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle), // Biểu tượng hồ sơ
            label: 'Hồ sơ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF2d59a4),
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
