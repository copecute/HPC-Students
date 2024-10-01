import 'package:flutter/material.dart';
import 'package:hpc_students/Screen/menu/profile.dart';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? NetworkImage(avatarUrl!)
                      : AssetImage('assets/avatar.png') as ImageProvider, // Dùng ảnh tải từ mạng hoặc ảnh local
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Họ và Tên: $hoTen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Điện thoại: $dienThoai'),
              SizedBox(height: 8),
              Text('Ngày sinh: $ngaySinh'),
              SizedBox(height: 8),
              Text('Giới tính: $gioiTinh'),
              SizedBox(height: 8),
              Text('Trường THPT: $truongTHPT'),
              SizedBox(height: 8),
              Text('CMND: $cmnd'),
            ],
          ),
        ),
      ),
    );
  }
}
