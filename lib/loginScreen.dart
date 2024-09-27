import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart'; // File config chứa baseUrl
import 'main.dart'; // Màn hình Main
import 'cookie_provider.dart'; // Import CookieProvider
import 'package:provider/provider.dart'; // Import provider package
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

// Enum để quản lý trạng thái đăng nhập
enum LoginStatus { success, failure, redirect }

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // Biến để theo dõi trạng thái loading
  bool _obscureText = true; // Biến để ẩn/hiện mật khẩu

  @override
  void initState() {
    super.initState();
    _autoLogin(); // Thử đăng nhập tự động khi mở ứng dụng
  }

  Future<void> _autoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('username');
    String? savedPassword = prefs.getString('password');

    if (savedUsername != null && savedPassword != null) {
      setState(() {
        _isLoading = true; // Bắt đầu loading
      });

      // Gửi yêu cầu đăng xuất
      bool logoutSuccess = await _logout();

      // Nếu đăng xuất thành công thì tiếp tục đăng nhập
      if (logoutSuccess) {
        // Gửi yêu cầu đăng nhập
        LoginStatus status = await _attemptLogin(savedUsername, savedPassword);
        setState(() {
          _isLoading = false; // Kết thúc loading
        });

        if (status == LoginStatus.success || status == LoginStatus.redirect) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        }
      } else {
        setState(() {
          _isLoading = false; // Kết thúc loading
        });
        // Nếu đăng xuất không thành công, có thể thông báo cho người dùng
        // _showSnackBar('Đăng xuất không thành công, không thể tự động đăng nhập.');
      }
    }
  }

  Future<bool> _logout() async {
    // URL API đăng xuất
    String url = '$baseUrl/DangNhap/Logout';

    // Lấy cookie từ CookieProvider
    String cookie = Provider.of<CookieProvider>(context, listen: false).getCookie() ?? '';

    // Gửi yêu cầu GET đến API đăng xuất
    try {
      var response = await http.get(
        Uri.parse(url),
        headers: {'Cookie': cookie}, // Sử dụng cookie từ Provider
      );

      if (response.statusCode == 200) {
        // Đăng xuất thành công
        Provider.of<CookieProvider>(context, listen: false).setCookie(''); // Xóa cookie hiện tại
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('cookie'); // Xóa cookie cũ khỏi SharedPreferences
        return true; // Đăng xuất thành công
      }
    } catch (e) {
      // Xử lý lỗi nếu cần
    }
    return false; // Đăng xuất không thành công
  }

  Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Kiểm tra tính hợp lệ của input
    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng nhập tên đăng nhập và mật khẩu.');
      return;
    }

    setState(() {
      _isLoading = true; // Bắt đầu loading
    });

    // Gửi yêu cầu đăng nhập
    LoginStatus status = await _attemptLogin(username, password);

    setState(() {
      _isLoading = false; // Kết thúc loading
    });

    switch (status) {
      case LoginStatus.success:
      case LoginStatus.redirect:
      // Lưu tài khoản, mật khẩu và cookie
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('username', username);
        prefs.setString('password', password);

        // Lưu cookie vào SharedPreferences
        String? cookie = Provider.of<CookieProvider>(context, listen: false).getCookie();
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

    // Lưu cookie vào CookieProvider
    String? cookie = response.headers['set-cookie'];
    if (cookie != null) {
      Provider.of<CookieProvider>(context, listen: false).setCookie(cookie);
    }

    // Lưu cookie vào SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('cookie', cookie ?? '');

    if (response.statusCode == 200) {
      // Đăng nhập thành công
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng nhập'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa
          children: [
            // Thêm logo
            Image.asset(
              'assets/icon.png', // Đường dẫn đến logo
              height: 100, // Chiều cao logo
            ),
            SizedBox(height: 20), // Khoảng cách giữa logo và form
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Mã sinh viên'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText; // Chuyển đổi trạng thái ẩn/hiện
                    });
                  },
                ),
              ),
              obscureText: _obscureText, // Sử dụng biến để ẩn/hiện mật khẩu
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login, // Vô hiệu hóa nút khi loading
              child: _isLoading
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}