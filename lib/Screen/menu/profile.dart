import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _hoTen = '';
  String _dienThoai = '';
  String _ngaySinh = '';
  String _gioiTinh = 'Nam321';
  String _truongTHPT = '';
  String _cmnd = '';
  String? _avatarUrl; // Variable to store the avatar URL

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data on initialization
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hoTen = prefs.getString('hoTen') ?? '';
      _dienThoai = prefs.getString('dienThoai') ?? '';
      _ngaySinh = prefs.getString('ngaySinh') ?? '';
      _gioiTinh = prefs.getString('gioiTinh') ?? 'Nam';
      _truongTHPT = prefs.getString('truongTHPT') ?? '';
      _cmnd = prefs.getString('cmnd') ?? '';
      _avatarUrl = prefs.getString('avatarUrl'); // Load avatar URL
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông Tin Sinh Viên'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _avatarUrl != null
                    ? NetworkImage(_avatarUrl!)
                    : AssetImage(
                        'assets/avatar.png'), // Use fetched avatar or local image
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Họ và Tên: $_hoTen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Điện thoại: $_dienThoai'),
            SizedBox(height: 8),
            Text('Ngày sinh: $_ngaySinh'),
            SizedBox(height: 8),
            Text('Giới tính: $_gioiTinh'),
            SizedBox(height: 8),
            Text('Trường THPT: $_truongTHPT'),
            SizedBox(height: 8),
            Text('CMND: $_cmnd'),
          ],
        ),
      ),
    );
  }
}
