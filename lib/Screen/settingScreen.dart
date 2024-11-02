import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hpc_students/include/theme_provider.dart';
import 'package:hpc_students/Screen/loginScreen.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String _appVersion = '';
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _autoLoginEnabled = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getAppVersion();
    _checkLoginStatus();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _autoLoginEnabled = prefs.getBool('auto_login_enabled') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('auto_login_enabled', _autoLoginEnabled);

    // Nếu tắt tự động đăng nhập, xóa thông tin đăng nhập đã lưu
    if (!_autoLoginEnabled) {
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.remove('cookie');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored preferences
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận đăng xuất'),
          content: Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Đăng xuất'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  // Thêm phương thức để mã hóa query parameters
  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // Sửa lại phương thức _launchURL cho phần gửi email
  Future<void> _launchURL(String url) async {
    if (url.startsWith('mailto:')) {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: 'hpc@minhgiang.pro',
        query: encodeQueryParameters({
          'subject': 'Hỗ trợ & Phản hồi - HPC Students',
          'body': 'Nội dung phản hồi:'
        }),
      );

      try {
        if (await canLaunch(emailLaunchUri.toString())) {
          await launch(emailLaunchUri.toString());
        } else {
          // Hiển thị dialog khi không thể mở ứng dụng email
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Không thể mở ứng dụng email'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vui lòng gửi email đến địa chỉ:'),
                    SelectableText('hpc@minhgiang.pro'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Đóng'),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        print('Error launching email: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở ứng dụng email')),
        );
      }
    } else {
      // Xử lý các URL thông thường
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở liên kết')),
        );
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? cookie = prefs.getString('cookie');
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');

    setState(() {
      // Chỉ coi là đã đăng nhập khi có đủ cả cookie và thông tin đăng nhập
      _isLoggedIn = cookie != null &&
          cookie.isNotEmpty &&
          username != null &&
          username.isNotEmpty &&
          password != null &&
          password.isNotEmpty;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLoginStatus(); // Kiểm tra lại trạng thái đăng nhập khi màn hình được focus
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          // Theme Settings
          ListTile(
            title: Text('Giao diện'),
            subtitle: Text('Chọn chế độ sáng hoặc tối'),
            trailing: DropdownButton<ThemeMode>(
              value: themeProvider.themeMode,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  themeProvider.toggleTheme(newValue);
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Hệ thống'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Sáng'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Tối'),
                ),
              ],
            ),
          ),
          Divider(),

          // Notifications Settings
          SwitchListTile(
            title: Text('Thông báo'),
            subtitle: Text('Bật/tắt thông báo từ ứng dụng'),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
                _saveSettings();
              });
            },
            activeColor: Color(0xFF2d59a4),
          ),
          Divider(),

          // Auto Login Settings
          SwitchListTile(
            title: Text('Tự động đăng nhập'),
            subtitle: Text('Tự động đăng nhập khi mở ứng dụng'),
            value: _autoLoginEnabled,
            onChanged: (bool value) {
              setState(() {
                _autoLoginEnabled = value;
                _saveSettings();
              });
            },
            activeColor: Color(0xFF2d59a4),
          ),
          Divider(),

          // About Section
          ListTile(
            title: Text('Về ứng dụng'),
            subtitle: Text('Phiên bản $_appVersion'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'HPC Students',
                applicationVersion: _appVersion,
                applicationIcon: Image.asset(
                  'assets/icon.png',
                  width: 50,
                  height: 50,
                ),
                children: [
                  Text(
                      'HPC Student - Ứng dụng cho sinh viên CĐ CNBKHN!\nỨng dụng giúp quản lý học tập hiệu quả với:\n✅ Thống kê kết quả học tập: Theo dõi tiến độ học tập.\n✅ Tra cứu bảng điểm: Kiểm tra và tính toán điểm.\n✅ Thời khóa biểu thông minh: Xem thời khóa biểu nhanh chóng.\n✅ CLUB Thịt Chó Bách Khoa: Tham gia câu lạc bộ cho những người yêu thích ẩm thực.\n'),
                ],
                applicationLegalese: 'Application developed by copecute',
              );
            },
          ),
          Divider(),

          // Support & Feedback
          ListTile(
            title: Text('Hỗ trợ & Phản hồi'),
            subtitle: Text('Liên hệ với chúng tôi qua email'),
            onTap: () {
              _launchURL(
                  'mailto:hpc@minhgiang.pro?subject=Hỗ trợ & Phản hồi - HPC Students');
            },
          ),
          Divider(),

          // liên hệ
          ListTile(
            title: Text('Liên hệ'),
            subtitle: Text('Liên hệ với chúng tôi qua website'),
            onTap: () {
              _launchURL('https://hpc-students.blogspot.com/p/contact-us.html');
            },
          ),
          Divider(),

          // Privacy Policy
          ListTile(
            title: Text('Chính sách bảo mật'),
            onTap: () {
              _launchURL(
                  'https://hpc-students.blogspot.com/p/privacy-policy.html');
            },
          ),
          Divider(),

          // Terms of Service
          ListTile(
            title: Text('Điều khoản sử dụng'),
            onTap: () {
              _launchURL(
                  'https://hpc-students.blogspot.com/p/terms-of-service.html');
            },
          ),
          Divider(),

          // Chỉ hiển thị nút đăng xuất nếu đã đăng nhập
          if (_isLoggedIn) ...[
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _showLogoutDialog,
                child: Text('Đăng xuất'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
