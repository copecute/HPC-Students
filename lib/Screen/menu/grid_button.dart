import 'package:flutter/material.dart';

class GridButton extends StatelessWidget {
  final int id;
  final IconData icon;
  final String label;
  final Color color;
  final Function onTap;

  const GridButton({
    Key? key,
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(8),
      splashColor: color.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  static List<Map<String, dynamic>> getButtons() {
    return [
      {
        'id': 1,
        'icon': Icons.add_chart,
        'label': 'Kết quả học tập',
        'color': Colors.green
      },
      {
        'id': 2,
        'icon': Icons.car_rental,
        'label': 'Vé ra vào',
        'color': Colors.red
      },
      {
        'id': 3,
        'icon': Icons.calendar_today,
        'label': 'Thời khoá biểu',
        'color': Colors.blue
      },
      {
        'id': 4,
        'icon': Icons.score,
        'label': 'Điểm rèn luyện',
        'color': Colors.deepOrange
      },
      {
        'id': 5,
        'icon': Icons.favorite,
        'label': 'Tìm người yêu',
        'color': Colors.pink
      },
      {
        'id': 6,
        'icon': Icons.image,
        'label': 'Chia sẻ ảnh',
        'color': Colors.deepOrange
      },
      {
        'id': 7,
        'icon': Icons.sentiment_satisfied_alt_outlined,
        'label': 'Lớp học Online',
        'color': Colors.teal
      },
      {
        'id': 8,
        'icon': Icons.stars,
        'label': 'HPC Ranking',
        'color': Colors.indigo
      },
      {
        'id': 9,
        'icon': Icons.monetization_on,
        'label': 'Học phí',
        'color': Colors.brown
      },
      {
        'id': 10,
        'icon': Icons.food_bank,
        'label': 'Đặt đồ căng tin',
        'color': Colors.yellow
      },
      {
        'id': 11,
        'icon': Icons.rate_review,
        'label': 'HPC Confession',
        'color': Colors.purple
      },
      {
        'id': 12,
        'icon': Icons.mark_email_unread_sharp,
        'label': 'Quản lý yêu cầu',
        'color': Colors.teal
      },
      {
        'id': 13,
        'icon': Icons.newspaper,
        'label': 'Bài viết',
        'color': Colors.blueGrey
      },
      {
        'id': 14,
        'icon': Icons.pets,
        'label': 'CLUB Thịt Chó Bách Khoa',
        'color': Colors.red
      },
      {
        'id': 15,
        'icon': Icons.card_membership_sharp,
        'label': 'Tra cứu văn bằng',
        'color': Colors.amber
      },
      {
        'id': 16,
        'icon': Icons.book,
        'label': 'Sách thư viện',
        'color': Colors.green
      },
      {
        'id': 17,
        'icon': Icons.shopping_bag,
        'label': 'Chợ sinh viên HPC',
        'color': Colors.blue
      },
      {
        'id': 18,
        'icon': Icons.settings,
        'label': 'Cài đặt',
        'color': Colors.grey
      },
    ];
  }
}
