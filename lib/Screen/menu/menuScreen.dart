import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hpc_students/Screen/menu/profile_card.dart'; // Import ProfileCard
import 'package:hpc_students/Screen/menu/grid_button.dart'; // Import GridButton
import 'package:shared_preferences/shared_preferences.dart';
import '../../include/theme_provider.dart'; // Import ThemeProvider
import 'package:hpc_students/Screen/menu/data_service.dart'; // Import the new data service
import 'package:hpc_students/Screen/menu/navigation_service.dart'; // Import the new navigation service
import 'package:hpc_students/Screen/menu/dialog_service.dart'; // Import the new dialog service

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _hoTen = ''; // Initialize hoTen
  String _dienThoai = ''; // Initialize dienThoai
  String _ngaySinh = '';
  String _gioiTinh = 'Nam';
  String _truongTHPT = '';
  String _cmnd = '';
  String _maSinhVien = ''; // Declare the maSinhVien variable
  bool _isLoading = true;
  String? _avatarUrl; // Declare the avatar URL variable
  bool _isFetched = false; // Track if data has been fetched

  @override
  void initState() {
    super.initState();
    _loadData().then((_) {
      setState(() {
        _isLoading = false;
      });
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

    if (!forceRefresh && cachedHoTen != null && cachedDienThoai != null) {
      print("Using cached data: $_hoTen, $_dienThoai"); // Debugging line
      setState(() {
        _hoTen = cachedHoTen;
        _dienThoai = cachedDienThoai;
        _ngaySinh = cachedNgaySinh ?? '';
        _gioiTinh = cachedGioiTinh ?? 'Nam';
        _truongTHPT = cachedTruongTHPT ?? '';
        _cmnd = cachedCmnd ?? '';
        _avatarUrl = cachedAvatarUrl; // Use cached avatar URL
        _isFetched = true; // Mark data as fetched
        _isLoading = false; // Set loading to false immediately
      });
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
        // Optionally, you can also call the avatar_service here if needed
        // await avatarService.saveAvatarToFirebase(avatarUrl, _dienThoai, _maSinhVien);
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
    );

    // Save fetched data to SharedPreferences
    await prefs.setString('hoTen', _hoTen);
    await prefs.setString('dienThoai', _dienThoai);
    await prefs.setString('ngaySinh', _ngaySinh);
    await prefs.setString('gioiTinh', _gioiTinh);
    await prefs.setString('truongTHPT', _truongTHPT);
    await prefs.setString('cmnd', _cmnd);
    await prefs.setString('avatarUrl', _avatarUrl ?? ''); // Save avatar URL
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
          PopupMenuButton<ThemeMode>(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.wb_sunny // Sun icon for light theme
                  : Icons.nights_stay, // Moon icon for dark theme
            ),
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
