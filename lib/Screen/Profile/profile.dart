import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/Screen/loginScreen.dart';
import 'doiMatKhau.dart'; // Import the change password screen

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _hoTen = '';
  String _dienThoai = '';
  String _ngaySinh = '';
  String _gioiTinh = '';
  String _truongTHPT = '';
  String _cmnd = '';
  String? _avatarUrl; // Variable to store the avatar URL
  String _tinh = ''; // New variable for province
  String _huyen = ''; // New variable for district
  String _xa = 'Thị trấn Hoà Thuận'; // New variable for commune
  String _chuyenNganh = ''; // New variable for Chuyên ngành
  String _heDaoTao = ''; // New variable for Hệ đào tạo
  String _khoaHoc = ''; // New variable for Khóa học
  String _nienKhoa = ''; // New variable for Niên khóa
  String _danToc = ''; // New variable for Dân tộc
  String _quocTich = ''; // New variable for Quốc tịch
  String _tonGiao = ''; // New variable for Tôn giáo

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
      _gioiTinh = prefs.getString('gioiTinh') ?? '';
      _truongTHPT = prefs.getString('truongTHPT') ?? '';
      _cmnd = prefs.getString('cmnd') ?? '';
      _avatarUrl = prefs.getString('avatarUrl'); // Load avatar URL
      _tinh = prefs.getString('tinh') ?? ''; // Load province
      _huyen = prefs.getString('huyen') ?? ''; // Load district
      _xa = prefs.getString('xa') ?? ''; // Load commune
      _chuyenNganh = prefs.getString('chuyenNganh') ?? ''; // Load Chuyên ngành
      _heDaoTao = prefs.getString('heDaoTao') ?? ''; // Load Hệ đào tạo
      _khoaHoc = prefs.getString('khoaHoc') ?? ''; // Load Khóa học
      _nienKhoa = prefs.getString('nienKhoa') ?? ''; // Load Niên khóa
      _danToc = prefs.getString('danToc') ?? ''; // Load Dân tộc
      _quocTich = prefs.getString('quocTich') ?? ''; // Load Quốc tịch
      _tonGiao = prefs.getString('tonGiao') ?? ''; // Load Tôn giáo
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _avatarUrl != null
                      ? NetworkImage(_avatarUrl!)
                      : AssetImage('assets/avatar.png'),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_hoTen',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    FutureBuilder(
                      future: SharedPreferences.getInstance()
                          .then((prefs) => prefs.getString('username')),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (snapshot.hasData) {
                          return Text('@${snapshot.data}');
                        } else {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          });
                          return SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ),
              ),
              _buildInfoRow('Điện thoại:', _dienThoai),
              _buildInfoRow('Ngày sinh:', _ngaySinh),
              _buildInfoRow('Giới tính:', _gioiTinh),
              _buildInfoRow('Trường THPT:', _truongTHPT),
              _buildInfoRow('CMND:', _cmnd),
              _buildInfoRow(
                  'Địa chỉ thường trú:', '${_xa},\n ${_huyen},\n ${_tinh}'),
              _buildInfoRow(
                  'Chuyên ngành:', _chuyenNganh), // Display Chuyên ngành
              _buildInfoRow('Hệ đào tạo:', _heDaoTao), // Display Hệ đào tạo
              _buildInfoRow('Khóa học:', _khoaHoc), // Display Khóa học
              _buildInfoRow('Niên khóa:', _nienKhoa), // Display Niên khóa
              _buildInfoRow('Dân tộc:', _danToc), // Display Dân tộc
              _buildInfoRow('Quốc tịch:', _quocTich), // Display Quốc tịch
              _buildInfoRow('Tôn giáo:', _tonGiao), // Display Tôn giáo
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DoiMatKhauScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2d59a4),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Đổi Mật Khẩu',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
