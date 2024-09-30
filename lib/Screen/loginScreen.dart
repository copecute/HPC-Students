import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../include/config.dart';
import '../main.dart';
import '../include/cookie_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../include/theme_provider.dart'; // Import ThemeProvider

enum LoginStatus { success, failure, redirect }

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('username');
    String? savedPassword = prefs.getString('password');

    if (savedUsername != null && savedPassword != null) {
      setState(() {
        _isLoading = true;
      });
      LoginStatus status = await _attemptLogin(savedUsername, savedPassword);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (status == LoginStatus.success || status == LoginStatus.redirect) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    }
  }

  Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng nhập tên đăng nhập và mật khẩu.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    LoginStatus status = await _attemptLogin(username, password);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    switch (status) {
      case LoginStatus.success:
      case LoginStatus.redirect:
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('username', username);
        prefs.setString('password', password);

        String? cookie =
            Provider.of<CookieProvider>(context, listen: false).getCookie();
        if (cookie != null) {
          prefs.setString('cookie', cookie);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
        break;
      case LoginStatus.failure:
      default:
        _showSnackBar('Đăng nhập thất bại! Vui lòng kiểm tra lại thông tin.');
        break;
    }
  }

  Future<LoginStatus> _attemptLogin(String username, String password) async {
    String url = '$baseUrl/DangNhap/CheckLogin';

    Map<String, String> postData = {
      'Role': '0',
      'UserName': username,
      'Password': password,
    };

    var response = await http.post(
      Uri.parse(url),
      body: postData,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    String? cookie = response.headers['set-cookie'];
    if (cookie != null) {
      Provider.of<CookieProvider>(context, listen: false).setCookie(cookie);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('cookie', cookie ?? '');

    if (response.statusCode == 200) {
      if (response.body.contains('message=')) {
        var decodedResponse = Uri.parse(response.body);
        var queryParams = decodedResponse.queryParameters;
        var message = queryParams['message'];
        _showSnackBar(message ?? 'Đăng nhập thành công!');
        return LoginStatus.success;
      } else {
        return LoginStatus.success;
      }
    } else if (response.statusCode == 302) {
      var redirectUrl = response.headers['location'];
      if (redirectUrl != null && redirectUrl.contains('/SinhVien')) {
        return LoginStatus.redirect;
      }
    }
    return LoginStatus.failure;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Get the theme provider

    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng Nhập'),
        actions: [
          PopupMenuButton<ThemeMode>(
            icon: Icon(Icons.settings_brightness),
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
      backgroundColor: Theme.of(context)
          .scaffoldBackgroundColor, // Use the theme's background color
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon.png',
                height: 120,
              ),
              SizedBox(height: 20),
              Text(
                'Đăng Nhập',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.color, // Use the theme's text color
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Mã sinh viên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .inputDecorationTheme
                      .fillColor, // Use the theme's input field color
                  labelStyle: TextStyle(
                    color: Theme.of(context)
                        .inputDecorationTheme
                        .labelStyle
                        ?.color, // Use the theme's label color
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                ),
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color, // Use the theme's body text color
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .inputDecorationTheme
                      .fillColor, // Use the theme's input field color
                  labelStyle: TextStyle(
                    color: Theme.of(context)
                        .inputDecorationTheme
                        .labelStyle
                        ?.color, // Use the theme's label color
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context)
                          .iconTheme
                          .color, // Use the theme's icon color
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                obscureText: _obscureText,
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color, // Use the theme's body text color
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2d59a4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
