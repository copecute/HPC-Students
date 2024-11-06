import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hpc_students/include/theme_provider.dart';
import 'package:hpc_students/Screen/loginScreen.dart';
import 'dart:convert';

class SettingScreen extends StatefulWidget {
  final bool showLocationDialog;

  const SettingScreen({
    Key? key,
    this.showLocationDialog = false,
  }) : super(key: key);

  @override
  SettingScreenState createState() => SettingScreenState();
}

class SettingScreenState extends State<SettingScreen> {
  String _appVersion = '';
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _autoLoginEnabled = true;
  bool _isLoggedIn = false;
  String? _weatherLocation;
  String? _accessLocation;
  List<Map<String, dynamic>> vietnamProvinces = [];
  bool isLoadingProvinces = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getAppVersion();
    _checkLoginStatus();
    _fetchProvinces();

    // Thêm đoạn này để mở dialog sau khi widget được tạo
    if (widget.showLocationDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showLocationPickerDialog();
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _autoLoginEnabled = prefs.getBool('auto_login_enabled') ?? true;
      _weatherLocation = prefs.getString('weather_location_name') ?? 'Hà Nội';
      _accessLocation = prefs.getString('access_location') ?? 'Hà Nội';
      if (prefs.getString('weather_location') == null) {
        prefs.setString('weather_location', 'ha noi');
        prefs.setString('weather_location_name', 'Hà Nội');
      }
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

  Future<void> _fetchProvinces() async {
    setState(() {
      isLoadingProvinces = true;
    });

    try {
      // Sử dụng dữ liệu cứng từ JSON
      const String jsonData = '''
{
    "provinces": [
        {
            "id": "an giang",
            "name": "An Giang"
        },
        {
            "id": "vung tau",
            "name": "Bà Rịa – Vũng Tàu"
        },
        {
            "id": "bac giang",
            "name": "Bắc Giang"
        },
        {
            "id": "bac kan",
            "name": "Bắc Kạn"
        },
        {
            "id": "bac lieu",
            "name": "Bạc Liêu"
        },
        {
            "id": "bac ninh",
            "name": "Bắc Ninh"
        },
        {
            "id": "ben tre",
            "name": "Bến Tre"
        },
        {
            "id": "binh dinh",
            "name": "Bình Định"
        },
        {
            "id": "binh duong",
            "name": "Bình Dương"
        },
        {
            "id": "binh phuoc",
            "name": "Bình Phước"
        },
        {
            "id": "binh thuan",
            "name": "Bình Thuận"
        },
        {
            "id": "ca mau",
            "name": "Cà Mau"
        },
        {
            "id": "can tho",
            "name": "Cần Thơ"
        },
        {
            "id": "cao bang",
            "name": "Cao Bằng"
        },
        {
            "id": "da nang",
            "name": "Đà Nẵng"
        },
        {
            "id": "dak lak",
            "name": "Đắk Lắk"
        },
        {
            "id": "dak nong",
            "name": "Đắk Nông"
        },
        {
            "id": "dien bien",
            "name": "Điện Biên"
        },
        {
            "id": "dong nai",
            "name": "Đồng Nai"
        },
        {
            "id": "dong thap",
            "name": "Đồng Tháp"
        },
        {
            "id": "gia lai",
            "name": "Gia Lai"
        },
        {
            "id": "ha giang",
            "name": "Hà Giang"
        },
        {
            "id": "ha nam",
            "name": "Hà Nam"
        },
        {
            "id": "ha noi",
            "name": "Hà Nội"
        },
        {
            "id": "ha tinh",
            "name": "Hà Tĩnh"
        },
        {
            "id": "hai duong",
            "name": "Hải Dương"
        },
        {
            "id": "hai phong",
            "name": "Hải Phòng"
        },
        {
            "id": "hau giang",
            "name": "Hậu Giang"
        },
        {
            "id": "hoa binh",
            "name": "Hòa Bình"
        },
        {
            "id": "hung yen",
            "name": "Hưng Yên"
        },
        {
            "id": "khanh hoa",
            "name": "Khánh Hòa"
        },
        {
            "id": "kien giang",
            "name": "Kiên Giang"
        },
        {
            "id": "kon tum",
            "name": "Kon Tum"
        },
        {
            "id": "lai chau",
            "name": "Lai Châu"
        },
        {
            "id": "lam dong",
            "name": "Lâm Đồng"
        },
        {
            "id": "lang son",
            "name": "Lạng Sơn"
        },
        {
            "id": "lao cai",
            "name": "Lào Cai"
        },
        {
            "id": "long an",
            "name": "Long An"
        },
        {
            "id": "nam dinh",
            "name": "Nam Định"
        },
        {
            "id": "nghe an",
            "name": "Nghệ An"
        },
        {
            "id": "ninh binh",
            "name": "Ninh Bình"
        },
        {
            "id": "ninh thuan",
            "name": "Ninh Thuận"
        },
        {
            "id": "phu tho",
            "name": "Phú Thọ"
        },
        {
            "id": "phu yen",
            "name": "Phú Yên"
        },
        {
            "id": "quang binh",
            "name": "Quảng Bình"
        },
        {
            "id": "quang nam",
            "name": "Quảng Nam"
        },
        {
            "id": "quang ngai",
            "name": "Quảng Ngãi"
        },
        {
            "id": "quang ninh",
            "name": "Quảng Ninh"
        },
        {
            "id": "quang tri",
            "name": "Quảng Trị"
        },
        {
            "id": "soc trang",
            "name": "Sóc Trăng"
        },
        {
            "id": "son la",
            "name": "Sơn La"
        },
        {
            "id": "tay ninh",
            "name": "Tây Ninh"
        },
        {
            "id": "thai binh",
            "name": "Thái Bình"
        },
        {
            "id": "thai nguyen",
            "name": "Thái Nguyên"
        },
        {
            "id": "thanh hoa",
            "name": "Thanh Hóa"
        },
        {
            "id": "thua thien hue",
            "name": "Thừa Thiên Huế"
        },
        {
            "id": "tien giang",
            "name": "Tiền Giang"
        },
        {
            "id": "tp ho chi minh",
            "name": "TP Hồ Chí Minh"
        },
        {
            "id": "tra vinh",
            "name": "Trà Vinh"
        },
        {
            "id": "tuyen quang",
            "name": "Tuyên Quang"
        },
        {
            "id": "vinh long",
            "name": "Vĩnh Long"
        },
        {
            "id": "vinh phuc",
            "name": "Vĩnh Phúc"
        },
        {
            "id": "yen bai",
            "name": "Yên Bái"
        }
    ]
}
      ''';

      final data = json.decode(jsonData);

      if (mounted) {
        setState(() {
          vietnamProvinces = List<Map<String, dynamic>>.from(data['provinces']);
          isLoadingProvinces = false;
        });
      }
    } catch (e) {
      print('Error loading provinces: $e');
      if (mounted) {
        setState(() {
          vietnamProvinces = [];
          isLoadingProvinces = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách tỉnh thành')),
      );
    }
  }

  void showLocationPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController searchController = TextEditingController();
        List<Map<String, dynamic>> filteredProvinces =
            List.from(vietnamProvinces);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Chọn vị trí thời tiết'),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm tỉnh thành...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          filteredProvinces = vietnamProvinces
                              .where((province) => province['name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    if (isLoadingProvinces)
                      Center(child: CircularProgressIndicator())
                    else
                      Container(
                        height: 300,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredProvinces.length,
                          itemBuilder: (context, index) {
                            final province = filteredProvinces[index];
                            return ListTile(
                              title: Text(province['name']),
                              onTap: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(
                                    'weather_location', province['id']);
                                await prefs.setString(
                                    'weather_location_name', province['name']);
                                await prefs.remove('cached_weather');
                                await prefs.remove('weather_cache_time');

                                setState(() {
                                  _weatherLocation = province['name'];
                                });

                                setStateDialog(() {});

                                Navigator.pop(context);
                              },
                              trailing: _weatherLocation == province['name']
                                  ? Icon(Icons.check,
                                      color: Theme.of(context).primaryColor)
                                  : null,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy'),
                ),
              ],
            );
          },
        );
      },
    );
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

          // Vị trí thời tiết
          ListTile(
            title: Text('Vị trí thời tiết'),
            subtitle: Text(_weatherLocation ?? 'Hà Nội'),
            onTap: () {
              showLocationPickerDialog();
            },
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
