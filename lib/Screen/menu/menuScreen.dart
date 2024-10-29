import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hpc_students/Screen/menu/profile_card.dart';
import 'package:hpc_students/Screen/menu/grid_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../include/theme_provider.dart';
import 'package:hpc_students/Screen/menu/data_service.dart';
import 'package:hpc_students/Screen/menu/navigation_service.dart';
import 'package:hpc_students/Screen/menu/dialog_service.dart';
import 'package:hpc_students/Screen/settingScreen.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _hoTen = ''; // Initialize hoTen
  String _dienThoai = ''; // Initialize dienThoai
  String _ngaySinh = '';
  String _gioiTinh = '';
  String _truongTHPT = '';
  String _cmnd = '';
  String _maSinhVien = ''; // Declare the maSinhVien variable
  bool _isLoading = true;
  String? _avatarUrl; // Declare the avatar URL variable
  bool _isFetched = false; // Track if data has been fetched
  String _tinh = ''; // Initialize province
  String _huyen = ''; // Initialize district
  String _xa = ''; // Initialize commune
  String _chuyenNganh = ''; // Initialize Chuyên ngành
  String _heDaoTao = ''; // Initialize Hệ đào tạo
  String _khoaHoc = ''; // Initialize Khóa học
  String _nienKhoa = ''; // Initialize Niên khóa
  String _danToc = ''; // Initialize Dân tộc
  String _quocTich = ''; // Initialize Quốc tịch
  String _tonGiao = ''; // Initialize Tôn giáo

  @override
  void initState() {
    super.initState();
    _loadData().then((_) {
      if (mounted) {
        // Kiểm tra xem widget có còn tồn tại không
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    print("Loading data..."); // Debugging line
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedHoTen = prefs.getString('hoTen');
    String? cachedDienThoai = prefs.getString('dienThoai');
    String? cachedNgaySinh = prefs.getString('ngaySinh');
    String? cachedGioiTinh = prefs.getString('gioiTinh');
    String? cachedTruongTHPT = prefs.getString('truongTHPT');
    String? cachedCmnd = prefs.getString('cmnd');
    String? cachedAvatarUrl = prefs.getString('avatarUrl');
    String? cachedTinh = prefs.getString('tinh');
    String? cachedHuyen = prefs.getString('huyen');
    String? cachedXa = prefs.getString('xa');
    String? cachedChuyenNganh = prefs.getString('chuyenNganh');
    String? cachedHeDaoTao = prefs.getString('heDaoTao');
    String? cachedKhoaHoc = prefs.getString('khoaHoc');
    String? cachedNienKhoa = prefs.getString('nienKhoa');
    String? cachedDanToc = prefs.getString('danToc');
    String? cachedQuocTich = prefs.getString('quocTich');
    String? cachedTonGiao = prefs.getString('tonGiao');

    if (!forceRefresh && cachedHoTen != null && cachedDienThoai != null) {
      print("Using cached data: $_hoTen, $_dienThoai"); // Debugging line
      if (mounted) {
        // Kiểm tra xem widget có còn tồn tại không
        setState(() {
          _hoTen = cachedHoTen;
          _dienThoai = cachedDienThoai;
          _ngaySinh = cachedNgaySinh ?? '';
          _gioiTinh = cachedGioiTinh ?? '';
          _truongTHPT = cachedTruongTHPT ?? '';
          _cmnd = cachedCmnd ?? '';
          _avatarUrl = cachedAvatarUrl; // Use cached avatar URL
          _tinh = cachedTinh ?? ''; // Use cached province
          _huyen = cachedHuyen ?? ''; // Use cached district
          _xa = cachedXa ?? ''; // Use cached commune
          _chuyenNganh = cachedChuyenNganh ?? ''; // Use cached Chuyên ngành
          _heDaoTao = cachedHeDaoTao ?? ''; // Use cached Hệ đào tạo
          _khoaHoc = cachedKhoaHoc ?? ''; // Use cached Khóa học
          _nienKhoa = cachedNienKhoa ?? ''; // Use cached Niên khóa
          _danToc = cachedDanToc ?? ''; // Use cached Dân tộc
          _quocTich = cachedQuocTich ?? ''; // Use cached Quốc tịch
          _tonGiao = cachedTonGiao ?? ''; // Use cached Tôn giáo
          _isFetched = true; // Mark data as fetched
          _isLoading = false; // Set loading to false immediately
        });
      }
      return; // Skip loading from the server
    }

    // Proceed to load data from the server if no cached data or forced refresh
    setState(() {
      _isLoading = true; // Show loading state while fetching data
    });

    // Load data from data_service and avatar_service
    await loadData(
      context,
      setState,
      _maSinhVien,
      _dienThoai,
      (hoTen) {
        setState(() {
          _hoTen = hoTen; // Set hoTen from data_service
        });
      },
      (dienThoai) {
        setState(() {
          _dienThoai = dienThoai; // Set dienThoai from data_service
        });
      },
      (avatarUrl) async {
        setState(() {
          _avatarUrl = avatarUrl; // Ensure this is set correctly
        });
      },
      (isLoading) {
        setState(() {
          _isLoading = isLoading; // Ensure loading state is set
        });
      },
      (isFetched) {
        setState(() {
          _isFetched = isFetched; // Ensure fetched state is set
        });
      },
      (ngaySinh) {
        setState(() {
          _ngaySinh = ngaySinh; // Set ngaySinh from data_service
        });
      },
      (gioiTinh) {
        setState(() {
          _gioiTinh = gioiTinh; // Set gioiTinh from data_service
        });
      },
      (truongTHPT) {
        setState(() {
          _truongTHPT = truongTHPT; // Set truongTHPT from data_service
        });
      },
      (cmnd) {
        setState(() {
          _cmnd = cmnd; // Set cmnd from data_service
        });
      },
      (tinh) {
        setState(() {
          _tinh = tinh; // Set province from data_service
        });
      },
      (huyen) {
        setState(() {
          _huyen = huyen; // Set district from data_service
        });
      },
      (xa) {
        setState(() {
          _xa = xa; // Set commune from data_service
        });
      },
      (chuyenNganh) {
        setState(() {
          _chuyenNganh = chuyenNganh; // Set Chuyên ngành from data_service
        });
      },
      (heDaoTao) {
        setState(() {
          _heDaoTao = heDaoTao; // Set Hệ đào tạo from data_service
        });
      },
      (khoaHoc) {
        setState(() {
          _khoaHoc = khoaHoc; // Set Khóa học from data_service
        });
      },
      (nienKhoa) {
        setState(() {
          _nienKhoa = nienKhoa; // Set Niên khóa from data_service
        });
      },
      (danToc) {
        setState(() {
          _danToc = danToc; // Set Dân tộc from data_service
        });
      },
      (quocTich) {
        setState(() {
          _quocTich = quocTich; // Set Quốc tịch from data_service
        });
      },
      (tonGiao) {
        setState(() {
          _tonGiao = tonGiao; // Set Tôn giáo from data_service
        });
      },
    );

    // Save fetched data to SharedPreferences
    await prefs.setString('hoTen', _hoTen);
    await prefs.setString('dienThoai', _dienThoai);
    await prefs.setString('ngaySinh', _ngaySinh);
    await prefs.setString('gioiTinh', _gioiTinh);
    await prefs.setString('truongTHPT', _truongTHPT);
    await prefs.setString('cmnd', _cmnd);
    await prefs.setString('avatarUrl', _avatarUrl ?? ''); // Save avatar URL
    await prefs.setString('tinh', _tinh); // Save province
    await prefs.setString('huyen', _huyen); // Save district
    await prefs.setString('xa', _xa); // Save commune
    await prefs.setString('chuyenNganh', _chuyenNganh); // Save Chuyên ngành
    await prefs.setString('heDaoTao', _heDaoTao); // Save Hệ đào tạo
    await prefs.setString('khoaHoc', _khoaHoc); // Save Khóa học
    await prefs.setString('nienKhoa', _nienKhoa); // Save Niên khóa
    await prefs.setString('danToc', _danToc); // Save Dân tộc
    await prefs.setString('quocTich', _quocTich); // Save Quốc tịch
    await prefs.setString('tonGiao', _tonGiao); // Save Tôn giáo
  }

  // Refresh data when pulled down
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true; // Show loading state while fetching data
    });

    // Always call _loadData with forceRefresh set to true
    await _loadData(
        forceRefresh:
            true); // This will call the data_service and avatar_service

    // After loading data, set loading to false
    setState(() {
      _isLoading = false; // Hide loading state after data is fetched
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Get the theme provider

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hồ sơ',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2d59a4),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData, // Call _refreshData when pulled down
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Use ProfileCard widget and pass the necessary data
                    ProfileCard(
                      hoTen: _hoTen,
                      dienThoai: _dienThoai,
                      ngaySinh: _ngaySinh,
                      gioiTinh: _gioiTinh,
                      truongTHPT: _truongTHPT,
                      cmnd: _cmnd,
                      avatarUrl: _avatarUrl, // Ensure this is set correctly
                    ),
                    // GridView hiển thị các chức năng (scrollable)
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: GridButton.getButtons().length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final button = GridButton.getButtons()[index];
                          return GridButton(
                            id: button['id'],
                            icon: button['icon'],
                            label: button['label'],
                            color: button['color'],
                            onTap: () {
                              _handleNavigation(context, button['id']);
                            },
                          );
                        },
                      ),
                    ),
                    // Nút đăng xuất (fixed)
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        onPressed: () {
                          _showLogoutConfirmationDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2d59a4),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text(
                          'Đăng xuất',
                          style: TextStyle(
                            fontSize: 16,
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

  void _showLogoutConfirmationDialog(BuildContext context) {
    showLogoutConfirmationDialog(context); // Updated line
  }

  Future<void> _handleNavigation(BuildContext context, int id) async {
    await handleNavigation(context, id); // Updated line
  }
}
