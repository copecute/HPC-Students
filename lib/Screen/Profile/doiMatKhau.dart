import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // Import for json encoding
import 'package:hpc_students/include/config.dart';
import 'package:hpc_students/Screen/loginScreen.dart'; // Import the LoginScreen
import 'package:provider/provider.dart';
import 'package:hpc_students/include/cookie_provider.dart'; // Import CookieProvider

class DoiMatKhauScreen extends StatefulWidget {
  @override
  _DoiMatKhauScreenState createState() => _DoiMatKhauScreenState();
}

class _DoiMatKhauScreenState extends State<DoiMatKhauScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true; // Added for current password visibility
  bool _obscureNewPassword = true; // Added for new password visibility
  bool _obscureConfirmPassword = true; // Added for confirm password visibility

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _changePassword() async {
    String currentPassword = _currentPasswordController.text;
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar(
          "Vui lòng không để trống các ô mật khẩu!"); // Show error message
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar("Mật khẩu mới không khớp!"); // Show error message
      return;
    }

    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Xác nhận thay đổi mật khẩu"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text("Bạn có chắc chắn muốn thay đổi mật khẩu không?",
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text(
                    "Lưu ý: Hãy ghi nhớ mật khẩu mới của bạn! Nếu quên mật khẩu, bạn sẽ không thể đăng nhập được vào hệ thống!",
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.red,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text(
                    "Nếu đã quên mật khẩu hãy đến phòng đào tạo yêu cầu mật khẩu mới!",
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.red,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: Text("Đồng ý"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Prepare the data for the POST request
      final String url = '$baseUrl/SinhVien/ThayDoiMatKhau';
      final Map<String, String> data = {
        "NewPass": newPassword, // Ensure this is the new password
        "PassOld": currentPassword, // Ensure this is the old password
      };
      print(url);
      print(data); // Debugging line to check the data being sent

      // Retrieve the cookie
      String? cookie =
          Provider.of<CookieProvider>(context, listen: false).getCookie();

      // Send the POST request
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookie ?? '', // Include the cookie in the headers
          },
          body: json.encode(data),
        );

        print(response.body);

        if (response.statusCode == 200) {
          // Handle plain text response
          String responseBody =
              response.body.trim(); // Get the response body and trim whitespace
          if (responseBody == "True") {
            _showSnackBar("Đổi mật khẩu thành công!"); // Show success message
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      LoginScreen()), // Navigate to LoginScreen
            );
          } else if (responseBody == "False") {
            _showSnackBar("Mật khẩu cũ không đúng!"); // Show error message
          } else {
            _showSnackBar(
                "Đã xảy ra lỗi không xác định!"); // Handle unexpected response
          }
        } else {
          _showSnackBar(
              "Đã xảy ra lỗi khi đổi mật khẩu!"); // Show error message
        }
      } catch (e) {
        _showSnackBar(
            "Không thể kết nối đến máy chủ."); // Show connection error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đổi Mật Khẩu'),
      ),
      body: SingleChildScrollView(
        // Wrap in SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // assets/doi-mat-khau.svg
            SvgPicture.asset('assets/doi-mat-khau.svg',
                width: MediaQuery.of(context).size.width,
                height: null,
                fit: BoxFit.cover),
            TextField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureCurrentPassword,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                      _obscureConfirmPassword =
                          _obscureNewPassword; // Sync visibility
                    });
                  },
                ),
              ),
              obscureText: _obscureNewPassword,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2d59a4),
                padding: EdgeInsets.symmetric(vertical: 15),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Đổi mật khẩu',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
