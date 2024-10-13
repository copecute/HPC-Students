import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:hpc_students/include/config.dart';
import 'package:hpc_students/main.dart';
import 'package:hpc_students/include/cookie_provider.dart';
import 'package:hpc_students/Screen/lichHoc/traCuuLichHocScreen.dart'; // Import the TraCuuLichHocScreen
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // Import dart:io for handling SocketException
import 'dart:convert'; // Import dart:convert for JSON encoding/decoding
import 'package:hpc_students/Screen/lichHoc/lichHocCached.dart'; // Import the new LichHocCachedScreen
// Import for using platform channels

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
  final _formKey = GlobalKey<FormState>(); // Added form key

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

    try {
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
    } on SocketException {
      _showSnackBar('Không có kết nối internet. Vui lòng kiểm tra lại.');
      return LoginStatus.failure;
    } catch (e) {
      _showSnackBar('Đã xảy ra lỗi khi đăng nhập. Vui lòng thử lại.');
      return LoginStatus.failure;
    }
  }

  void _showSnackBar(String message) {
    // Delay the snackbar display to ensure it appears above the dialog
    Future.delayed(Duration(milliseconds: 100), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  void _showCachedScheduleButton() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedSchedule = prefs.getString('cachedSchedule');

    if (cachedSchedule != null) {
      // Navigate to the cached schedule screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              LichHocCachedScreen(), // Navigate to the new screen
        ),
      );
    }
  }

  // Add the button to view cached schedule
  Widget _buildViewCachedScheduleButton() {
    return FutureBuilder<String?>(
      future: SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('cachedSchedule')),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(); // Show nothing while loading
        } else if (snapshot.hasData && snapshot.data != null) {
          return ElevatedButton(
            onPressed: _showCachedScheduleButton,
            child: Text("Xem lịch học đã lưu"),
          );
        }
        return Container(); // Show nothing if no cached schedule
      },
    );
  }

  void _showRegisterConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Trở thành sinh viên HPC?"),
          content: Text(
              "Thủ tục đăng ký nhập học rất đơn giản bạn hãy tham gia ngay nào!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () async {
                const url =
                    'https://tuyensinh.bachkhoahanoi.edu.vn/'; // URL to launch
                if (await canLaunch(url)) {
                  await launch(url); // Launch the URL
                } else {
                  _showSnackBar('Không thể mở liên kết.');
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF2d59a4), // Match the login button color
              ),
              child: Text("Đăng ký"),
            ),
          ],
        );
      },
    );
  }

  void _showResetPasswordDialog() {
    final TextEditingController _maSVController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Đặt lại mật khẩu"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _maSVController,
                decoration: InputDecoration(hintText: "Mã sinh viên"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Hủy"),
            ),
            ElevatedButton(
              // Change to ElevatedButton for confirmation
              onPressed: () async {
                String maSV = _maSVController.text;
                if (maSV.isNotEmpty) {
                  // Call the reset password function
                  await _resetPassword(maSV);
                } else {
                  _showAlertDialog('Vui lòng nhập mã sinh viên.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF2d59a4), // Match the login button color
              ),
              child: Text("Xác nhận"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetPassword(String maSV) async {
    String url = '$baseUrl/DangNhap/ResetPassWord';
    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode({'Ma_sv': maSV}),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        switch (result.toString()) {
          case "1":
            _showAlertDialog('Bạn không có Email đăng ký với nhà trường!');
            break;
          case "2":
            _showAlertDialog('Xin hãy truy cập Email để lấy lại mật khẩu!');
            break;
          case "3":
            _showAlertDialog('Mã sinh viên bạn nhập không đúng!');
            break;
          case "4":
            _showAlertDialog('Không có tài khoản sinh viên này!');
            break;
          case "5":
            _showAlertDialog('Bạn không có quyền sử dụng chức năng này!');
            break;
          default:
            _showAlertDialog('Có lỗi đã xảy ra!');
            break;
        }
      } else {
        _showAlertDialog('Có lỗi xảy ra khi kết nối đến máy chủ.');
      }
    } catch (e) {
      _showAlertDialog('Đã xảy ra lỗi khi đặt lại mật khẩu.');
    }
  }

  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Thông báo"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the current brightness of the system
    final brightness = MediaQuery.of(context).platformBrightness;

    return Scaffold(
      backgroundColor: brightness == Brightness.dark
          ? Color(0xFF282a36) // Set background to black for dark mode
          : Colors.white, // Set background to white for light mode
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  SizedBox(height: constraints.maxHeight * 0.1),
                  Image.asset(
                    "assets/icon.png", // Update with your new logo path
                    height: 100,
                  ),
                  SizedBox(height: 30),
                  Text(
                    "CỔNG THÔNG TIN SINH VIÊN",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.1),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Mã sinh viên', // Updated hint text
                            filled: true,
                            fillColor: brightness == Brightness.dark
                                ? Colors.grey[800] // Dark input field color
                                : const Color.fromARGB(255, 188, 187,
                                    187), // Light input field color
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0 * 1.5, vertical: 16.0),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50)),
                            ),
                          ),
                          controller: _usernameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mã sinh viên';
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: TextFormField(
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              hintText: 'Mật khẩu',
                              filled: true,
                              fillColor: brightness == Brightness.dark
                                  ? Colors.grey[800] // Dark input field color
                                  : const Color.fromARGB(255, 188, 187,
                                      187), // Light input field color
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0 * 1.5, vertical: 16.0),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50)),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                            controller: _passwordController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu';
                              }
                              return null;
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading // Disable button when loading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    _login(); // Call the existing login method
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF2d59a4),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: const StadiumBorder(),
                          ),
                          child:
                              _isLoading // Show loading indicator when logging in
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      "Đăng nhập"), // Updated button text
                        ),

                        const SizedBox(height: 16.0),
                        // Row for the two buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _showResetPasswordDialog, // Show modal
                              child: Text(
                                'Quên mật khẩu?',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: brightness == Brightness.dark
                                          ? Colors
                                              .white70 // Light text for dark theme
                                          : Colors
                                              .black54, // Dark text for light theme
                                    ),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  _showRegisterConfirmationDialog, // Show confirmation dialog
                              child: Text.rich(
                                TextSpan(
                                  text: "Không có tài khoản? ",
                                  children: [
                                    TextSpan(
                                      text: "Đăng ký",
                                      style:
                                          TextStyle(color: Color(0xFF00BF6D)),
                                    ),
                                  ],
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: brightness == Brightness.dark
                                          ? Colors
                                              .white70 // Light text for dark theme
                                          : Colors
                                              .black54, // Dark text for light theme
                                    ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16.0),
                        _buildViewCachedScheduleButton(),
                        const SizedBox(height: 16.0),
                        Text(
                          'Tra cứu văn bằng',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: brightness == Brightness.dark
                                        ? Colors
                                            .white70 // Light text for dark theme
                                        : Colors
                                            .black54, // Dark text for light theme
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
