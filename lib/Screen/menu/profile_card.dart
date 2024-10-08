import 'package:flutter/material.dart';
import 'package:hpc_students/Screen/Profile/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileCard extends StatelessWidget {
  final String hoTen;
  final String dienThoai;
  final String ngaySinh;
  final String gioiTinh;
  final String truongTHPT;
  final String cmnd;
  final String? avatarUrl;

  const ProfileCard({
    Key? key,
    required this.hoTen,
    required this.dienThoai,
    required this.ngaySinh,
    required this.gioiTinh,
    required this.truongTHPT,
    required this.cmnd,
    this.avatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center horizontally
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? NetworkImage(avatarUrl!)
                    : AssetImage('assets/avatar.png')
                        as ImageProvider, // Dùng ảnh tải từ mạng hoặc ảnh local
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Align text to the left
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center vertically
                  children: [
                    Text(
                      '$hoTen',
                      style: TextStyle(
                        fontSize: 20,
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
                          return Text('Mã sinh viên: ${snapshot.data}');
                        } else {
                          return Text('Xem trang cá nhân');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
