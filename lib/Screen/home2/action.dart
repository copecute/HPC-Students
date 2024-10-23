import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hpc_students/include/theme_provider.dart';

const double _kRadius = 12;

class ActionAndOverviewInfoCard extends StatelessWidget {
  const ActionAndOverviewInfoCard({
    super.key,
    required this.contentPadding,
    required this.borderRadius,
  });

  final EdgeInsetsGeometry contentPadding;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return CustomPaint(
      painter: _CardPainter(isDarkMode: isDarkMode),
      child: Padding(
        padding: contentPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionItem('Tìm người yêu', context),
            _buildActionItem('HPC Ranking', context),
            _buildActionItem('Tra điểm', context),
            _buildActionItem('Xem tất cả', context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(String label, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                    ? Colors.white
                    : Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CardPainter extends CustomPainter {
  final bool isDarkMode;

  _CardPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    paintActionArea(canvas, size);
  }

  void paintActionArea(Canvas canvas, Size size) {
    final stopX = size.width;
    final stopY = size.height;

    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, stopX, stopY),
      topLeft: const Radius.circular(_kRadius),
      topRight: const Radius.circular(_kRadius),
      bottomLeft: const Radius.circular(_kRadius),
      bottomRight: const Radius.circular(_kRadius),
    );
    final paint = Paint()
      ..color = isDarkMode ? Colors.grey[800]! : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
