import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hpc_students/Screen/menu/profile_card.dart'; // Import ProfileCard
import 'package:hpc_students/Screen/menu/grid_button.dart'; // Import GridButton
import '../../include/theme_provider.dart'; // Import ThemeProvider
import 'package:hpc_students/Screen/menu/data_service.dart'; // Import the new data service
import 'package:hpc_students/Screen/menu/navigation_service.dart'; // Import the new navigation service
import 'package:hpc_students/Screen/menu/user_data_service.dart'; // Import the new user data service
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
  bool _isFetched = false;

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data on initialization
  }

  Future<void> _loadData() async {
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
      (avatarUrl) {
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
    );
  }

  // Refresh data when pulled down
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true; // Show loading state while fetching data
    });
    await _loadData(); // Fetch data again
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
            : Column(
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
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.all(10),
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
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showLogoutConfirmationDialog(context); // Updated line
  }

  Future<void> _handleNavigation(BuildContext context, int id) async {
    await handleNavigation(context, id); // Updated line
  }
}
