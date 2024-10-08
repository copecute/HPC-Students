import 'package:flutter/material.dart';
import 'package:hpc_students/Screen/TraCuuDiemRenLuyenScreen.dart';
import 'package:hpc_students/Screen/traCuuVanBang.dart';
import 'package:hpc_students/Screen/veRaVao/traCuuRaVao.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hpc_students/Screen/Blog/blogScreen.dart';
import 'package:hpc_students/Screen/rankScreen.dart';
import 'package:hpc_students/Screen/traCuuHocPhiScreen.dart';
import 'package:hpc_students/Screen/traCuuLichHocScreen.dart';
import 'package:hpc_students/Screen/traDiemScreen.dart';
import 'package:hpc_students/Screen/timNguoiYeu/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

import '../yeuCau/traCuuYeuCau.dart';

Future<void> handleNavigation(BuildContext context, int id) async {
  switch (id) {
    case 2:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraDiemScreen()),
      );
      break;
    case 3:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraCuuRaVao()),
      );
      break;
    case 4:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraCuuLichHocScreen()),
      );
      break;
    case 5:
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username =
          prefs.getString('username'); // Get username from SharedPreferences

      if (username != null) {
        // Navigate to ChatScreen and add user to queue
        final DatabaseReference queueRef =
            FirebaseDatabase.instance.ref('queue');
        await queueRef.push().set(username); // Add user to queue

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              username: username,
            ),
          ),
        );
      } else {
        // Handle case where username is not found
        showSnackBar(context, 'Vui lòng đăng nhập lại!');
      }
      break;
    case 6:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraCuuDiemRenLuyenScreen()),
      );
      break;
    case 9:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RankScreen()),
      );
      break;
    case 10:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraCuuHocPhiScreen()),
      );
      break;
    case 12:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraCuuYeuCauScreen()),
      );
      break;
    case 13:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BlogScreen()),
      );
      break;
    case 14:
      final Uri url = Uri.parse('https://zalo.me/g/uttoza177');
      if (!await launchUrl(url)) {
        throw 'Không thể mở CLUB Thịt Chó Bách Khoa';
      }
      break;
    case 15:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraCuuVanBangScreen()),
      );
      break;
    default:
      showSnackBar(context, 'Chưa có chức năng này!');
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
