import 'package:flutter/material.dart';
import 'package:hpc_students/Screen/TraCuuDiemRenLuyenScreen.dart';
import 'package:hpc_students/Screen/imgur/homeImgur.dart';
import 'package:hpc_students/Screen/kiemSoatTruyCap/veXe.dart';
import 'package:hpc_students/Screen/traCuuVanBang.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hpc_students/Screen/Blog/blogScreen.dart';
import 'package:hpc_students/Screen/rankScreen.dart';
import 'package:hpc_students/Screen/traCuuHocPhiScreen.dart';
import 'package:hpc_students/Screen/lichHoc/traCuuLichHocScreen.dart';
import 'package:hpc_students/Screen/traDiemScreen.dart';
import 'package:hpc_students/Screen/timNguoiYeu/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

import '../settingScreen.dart';
import '../yeuCau/traCuuYeuCau.dart';

Future<void> handleNavigation(BuildContext context, int id) async {
  switch (id) {
    case 1:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraDiemScreen()),
      );
      break;
    case 2:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VeXeScreen()),
      );
      break;
    case 3:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraCuuLichHocScreen()),
      );
      break;
    case 4:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraCuuDiemRenLuyenScreen()),
      );
      break;
    case 5:
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username != null) {
        final DatabaseReference queueRef =
            FirebaseDatabase.instance.ref('queue');
        await queueRef.push().set(username);

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
        MaterialPageRoute(builder: (context) => HomeImgurScreen()),
      );
      break;
    case 7:
      final Uri url = Uri.parse('https://hoctructuyen.bachkhoahanoi.edu.vn/');
      if (!await launchUrl(url)) {
        throw 'Không thể mở hệ thống học trực tuyến';
      }
      break;
    case 8:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RankScreen()),
      );
      break;
    case 9:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraCuuHocPhiScreen()),
      );
      break;
    case 10:
      final Uri url =
          Uri.parse('https://www.facebook.com/profile.php?id=61553425276826');
      if (!await launchUrl(url)) {
        throw 'Không thể mở HPC Confession';
      }
      break;
    case 11:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraCuuYeuCauScreen()),
      );
      break;
    case 12:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BlogScreen()),
      );
      break;
    case 13:
      final Uri url = Uri.parse('https://zalo.me/g/uttoza177');
      if (!await launchUrl(url)) {
        throw 'Không thể mở CLUB Thịt Chó Bách Khoa';
      }
      break;
    case 14:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TraCuuVanBangScreen()),
      );
      break;
    case 15:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingScreen()),
      );
      break;
    default:
      showSnackBar(context, 'Chưa có chức năng này! hãy đợi phiên bản sau');
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
