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
import 'package:hpc_students/Screen/home/HomeScreen.dart';
import 'package:hpc_students/Screen/menu/menuScreen.dart';
import 'include/theme_provider.dart'; // Import ThemeProvider
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart'; // Import CurvedNavigationBar
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart'; // Import CurvedNavigationBarItem
import 'package:hpc_students/Screen/canteenShop/cart_provider.dart';
import 'package:hpc_students/Screen/LibraryBooks/library_cart_provider.dart';

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
        ChangeNotifierProvider(create: (_) => CartProvider()), // Thêm dòng này
        ChangeNotifierProvider(create: (_) => LibraryCartProvider()),
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
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey:
          _scaffoldMessengerKey, // Set the key for ScaffoldMessenger
      title: 'HPC Students',
      theme: themeProvider.lightTheme, // Light theme
      darkTheme: themeProvider.darkTheme, // Dark theme
      themeMode: themeProvider.themeMode, // Set the theme mode to system
      locale: WidgetsBinding.instance.window.locale,
      supportedLocales: [
        const Locale('en', 'US'), // English
        const Locale('vi', 'VN'), // Vietnamese
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
  int _selectedIndex = 0; // Current selected index
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey =
      GlobalKey(); // Key for CurvedNavigationBar

  final List<Widget> _screens = [
    HomeScreen(), // Home screen
    TraCuuLichHocScreen(), // Schedule screen
    TraDiemScreen(), // Results screen
    MenuScreen(), // Menu screen
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Access ThemeProvider
    return Scaffold(
      body: _screens[_selectedIndex], // Display the corresponding screen
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _selectedIndex,
        items: [
          CurvedNavigationBarItem(
              child: Icon(
                Icons.home,
                color: _selectedIndex == 0 // Check if this item is selected
                    ? themeProvider.themeMode == ThemeMode.dark ||
                            (themeProvider.themeMode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark)
                        ? Colors.blue
                        : themeProvider.lightTheme.primaryColor // Active color
                    : themeProvider.themeMode == ThemeMode.dark ||
                            (themeProvider.themeMode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark)
                        ? Colors.white
                        : Color(0xFF747474),
              ), // Icon color
              label: 'Trang chủ'),
          CurvedNavigationBarItem(
              child: Icon(
                Icons.calendar_today,
                color: _selectedIndex == 1 // Check if this item is selected
                    ? themeProvider.themeMode == ThemeMode.dark ||
                            (themeProvider.themeMode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark)
                        ? Colors.blue
                        : themeProvider.lightTheme.primaryColor // Active color
                    : themeProvider.themeMode == ThemeMode.dark ||
                            (themeProvider.themeMode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark)
                        ? Colors.white
                        : Color(0xFF747474),
              ), // Icon color
              label: 'Lịch học'),
          CurvedNavigationBarItem(
              child: Icon(
                Icons.add_chart,
                color: _selectedIndex == 2 // Check if this item is selected
                    ? themeProvider.themeMode == ThemeMode.dark ||
                            (themeProvider.themeMode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark)
                        ? Colors.blue
                        : themeProvider.lightTheme.primaryColor // Active color
                    : themeProvider.themeMode == ThemeMode.dark ||
                            (themeProvider.themeMode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark)
                        ? Colors.white
                        : Color(0xFF747474),
              ), // Icon color
              label: 'Kết quả học tập'),
          CurvedNavigationBarItem(
              child: Icon(
                Icons.account_circle,
                color: _selectedIndex == 3 // Check if this item is selected
                    ? themeProvider.themeMode == ThemeMode.dark ||
                            (themeProvider.themeMode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark)
                        ? Colors.blue
                        : themeProvider.lightTheme.primaryColor // Active color
                    : themeProvider.themeMode == ThemeMode.dark ||
                            (themeProvider.themeMode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark)
                        ? Colors.white
                        : Color(0xFF747474),
              ), // Icon color
              label: 'Hồ sơ'),
        ],
        color: themeProvider.themeMode == ThemeMode.dark ||
                (themeProvider.themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness ==
                        Brightness.dark)
            ? Color(0xFF1b1a1f)
            : Color(0xFFeeeeee),
        buttonBackgroundColor: themeProvider.themeMode == ThemeMode.dark ||
                (themeProvider.themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness ==
                        Brightness.dark)
            ? Color(0xFF1b1a1f)
            : Color(0xFFeeeeee),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Update selected index
          });
        },
        letIndexChange: (index) => true,
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
