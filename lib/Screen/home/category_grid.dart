import 'package:flutter/material.dart';
import 'package:hpc_students/Screen/TraCuuDiemRenLuyenScreen.dart';
import 'package:hpc_students/Screen/yeuCau/traCuuYeuCau.dart';
import 'package:hpc_students/Screen/lichHoc/traCuuLichHocScreen.dart';
import 'package:hpc_students/Screen/traDiemScreen.dart';
import 'package:hpc_students/Screen/traCuuHocPhiScreen.dart';
import 'package:hpc_students/Screen/timNguoiYeu/chat.dart';
import 'package:hpc_students/Screen/rankScreen.dart';
import 'package:hpc_students/Screen/menu/menuScreen.dart';

class CategoryGrid extends StatelessWidget {
  final String maSinhVien; // Pass the student ID to the widget

  CategoryGrid({required this.maSinhVien}); // Constructor to accept maSinhVien

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        // 4 mục trong một dòng
        crossAxisSpacing: 8,
        // Khoảng cách giữa các cột
        mainAxisSpacing: 8,
        // Khoảng cách giữa các hàng
        children: [
          _buildCategoryItem(Icons.calendar_today, 'Thời khoá biểu', context),
          _buildCategoryItem(Icons.add_chart, 'Kết quả học tập', context),
          _buildCategoryItem(Icons.monetization_on, 'Học phí', context),
          _buildCategoryItem(Icons.score, 'Điểm rèn luyện', context),
          _buildCategoryItem(Icons.favorite, 'Tìm người yêu', context),
          _buildCategoryItem(Icons.stars, 'HPC Ranking', context),
          _buildCategoryItem(
              Icons.mark_email_unread_sharp, 'Quản lý yêu cầu', context),
          _buildCategoryItem(Icons.grid_view, 'Tất cả', context),
        ],
      ),
    );
  }

  // Define the _buildCategoryItem method
  Widget _buildCategoryItem(IconData icon, String title, BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12), // Rounded corners
      elevation: 4, // Shadow effect
      child: InkWell(
        borderRadius: BorderRadius.circular(12), // Match the border radius
        onTap: () {
          // Handle tap action using switch case
          switch (title) {
            case 'Thời khoá biểu':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TraCuuLichHocScreen()),
              );
              break;
            case 'Kết quả học tập':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TraDiemScreen()),
              );
              break;
            case 'Học phí':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TraCuuHocPhiScreen()),
              );
              break;
            case 'Điểm rèn luyện':
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TraCuuDiemRenLuyenScreen()),
              );
              break;
            case 'Tìm người yêu':
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatScreen(username: maSinhVien)),
              );
              print("vào chat với username $maSinhVien");
              break;
            case 'HPC Ranking':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RankScreen()),
              );
              break;
            case 'Quản lý yêu cầu':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TraCuuYeuCauScreen()),
              );
              break;
            case 'Tất cả':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MenuScreen()),
              );
              break;
            default:
              showSnackBar(context, 'Chưa có chức năng này!');
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
