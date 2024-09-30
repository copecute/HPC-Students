import 'dart:io';
import 'package:hpc_students/Screen/profile.dart';
import 'package:hpc_students/include/config.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Database
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/include/cookie_provider.dart';
import 'package:hpc_students/Screen/loginScreen.dart';
import 'avatar_service.dart' as avatarService; // Import with alias

Future<void> loadData(
    BuildContext context,
    Function setState,
    String maSinhVien,
    String dienThoai,
    Function(String) setHoTen, // Callback for hoTen
    Function(String) setDienThoai, // Callback for dienThoai
    Function(String?) setAvatarUrl,
    Function(bool) setIsLoading,
    Function(bool) setIsFetched,
    Function(String) setNgaySinh, // Callback for ngaySinh
    Function(String) setGioiTinh, // Callback for gioiTinh
    Function(String) setTruongTHPT, // Callback for truongTHPT
    Function(String) setCmnd // Callback for cmnd
    ) async {
  String? cookie =
  Provider.of<CookieProvider>(context, listen: false).getCookie();

  if (cookie == null || cookie.isEmpty) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
    return;
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  maSinhVien = prefs.getString('maSinhVien') ?? ''; // Lấy maSinhVien

  final url = '$baseUrl/SinhVien/ThongTinSinhVien';
  final HttpClient httpClient = HttpClient()
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

  final ioClient = IOClient(httpClient);

  try {
    final response = await ioClient.get(
      Uri.parse(url),
      headers: {
        'Cookie': cookie,
      },
    );

    if (response.statusCode == 200) {
      var document = htmlParser.parse(response.body);

      setState(() {
        String hoTen =
            document.getElementById("Ho_ten")?.attributes['value'] ?? '';
        dienThoai =
            document.getElementById("Dienthoai_canhan")?.attributes['value'] ??
                '';
        String ngaySinh =
            document.getElementById("Ngay_sinh")?.attributes['value'] ?? '';
        String gioiTinh = document
            .getElementById("ID_gioi_tinh")
            ?.querySelector('option[selected]')?.text ??
            'Nam';
        String truongTHPT =
            document.getElementById("TruongTHPT")?.attributes['value'] ?? '';
        String cmnd =
            document.getElementById("CMND")?.attributes['value'] ?? '';

        // Set the data using the callbacks
        setHoTen(hoTen);
        setDienThoai(dienThoai);
        setNgaySinh(ngaySinh);
        setGioiTinh(gioiTinh);
        setTruongTHPT(truongTHPT);
        setCmnd(cmnd);

        setAvatarUrl(null); // Reset avatar URL
        setIsLoading(false);
      });

      await checkFirebaseForAvatar(context, maSinhVien, dienThoai, setState,
          setAvatarUrl, setIsLoading, setIsFetched);
    } else {
      setIsLoading(false);
    }
  } catch (e) {
    setIsLoading(false);
  } finally {
    ioClient.close();
  }
}

Future<void> checkFirebaseForAvatar(
    BuildContext context,
    String maSinhVien,
    String dienThoai,
    Function setState,
    Function(String?) setAvatarUrl,
    Function(bool) setIsLoading,
    Function(bool) setIsFetched) async {
  final DatabaseReference ref =
  FirebaseDatabase.instance.ref('Students_Profile/$maSinhVien');
  final DatabaseEvent event = await ref.once();

  if (event.snapshot.exists) {
    final data = event.snapshot.value as Map<dynamic, dynamic>;
    String? avatarUrl = data['avatar'];
    String? timestampString = data['timestamp'];

    if (avatarUrl != null && timestampString != null) {
      DateTime timestamp = DateTime.parse(timestampString);
      if (DateTime.now().difference(timestamp).inHours >= 2) {
        // If the timestamp is older than 2 hours, fetch a new avatar
        String? newAvatarUrl = await avatarService.fetchAvatarFromZalo(dienThoai);
        if (newAvatarUrl != null) {
          await avatarService.saveAvatarToFirebase(newAvatarUrl, dienThoai,
              maSinhVien); // Save new avatar to Firebase
          setState(() {
            setAvatarUrl(newAvatarUrl); // Update avatar URL
            setIsFetched(true);
            setIsLoading(false);
          });
        }
      } else {
        // Use the existing avatar
        setState(() {
          setAvatarUrl(avatarUrl); // Use existing avatar
          setIsFetched(true);
          setIsLoading(false);
        });
      }
    } else {
      // If no avatar or timestamp, fetch a new avatar
      String? newAvatarUrl = await avatarService.fetchAvatarFromZalo(dienThoai);
      if (newAvatarUrl != null) {
        await avatarService.saveAvatarToFirebase(
            newAvatarUrl, dienThoai, maSinhVien); // Save new avatar to Firebase
        setState(() {
          setAvatarUrl(newAvatarUrl); // Update avatar URL
          setIsFetched(true);
          setIsLoading(false);
        });
      }
    }
  } else {
    // If no data in Firebase, fetch a new avatar
    String? newAvatarUrl = await avatarService.fetchAvatarFromZalo(dienThoai);
    if (newAvatarUrl != null) {
      await avatarService.saveAvatarToFirebase(
          newAvatarUrl, dienThoai, maSinhVien); // Save new avatar to Firebase
      setState(() {
        setAvatarUrl(newAvatarUrl); // Update avatar URL
        setIsFetched(true);
        setIsLoading(false);
      });
    }
  }
}
