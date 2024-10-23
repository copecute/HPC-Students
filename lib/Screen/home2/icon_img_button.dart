import 'package:flutter/material.dart';

class IconImgButton extends StatelessWidget {
  const IconImgButton(
    this.iconName, {
    super.key,
    this.backgroundColor,
    this.onTap,
    this.size = 24, // Thêm tham số size với giá trị mặc định là 24
  });

  final String iconName;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double size; // Thêm thuộc tính size

  static const double tapTargetSize = 48;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: tapTargetSize,
        height: tapTargetSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            'assets/icons/$iconName',
            width: size, // Sử dụng size cho chiều rộng
            height: size, // Sử dụng size cho chiều cao
          ),
        ),
      ),
    );
  }
}
