import 'dart:io';
import 'package:hpc_students/Screen/profile.dart';
import 'package:hpc_students/include/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
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
  print("Starting to load data...");
  String? cookie =
      Provider.of<CookieProvider>(context, listen: false).getCookie();

  if (cookie == null || cookie.isEmpty) {
    print("No cookie found, redirecting to login.");
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
      print("Data loaded successfully.");
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
                ?.querySelector('option[selected]')
                ?.text ??
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
      print("Failed to load data, status code: ${response.statusCode}");
      setIsLoading(false);
    }
  } catch (e) {
    print("Error loading data: $e");
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
  final DocumentReference ref =
      FirebaseFirestore.instance.collection('Students_Profile').doc(maSinhVien);

  print("Checking Firestore for avatar... $maSinhVien");

  try {
    final DocumentSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      print("Avatar data found in Firestore.");
      final data = snapshot.data() as Map<String, dynamic>;
      String? avatarUrl = data['avatar'];
      Timestamp? timestamp = data['timestamp']; // Change to Timestamp

      if (avatarUrl != null && timestamp != null) {
        DateTime timestampDateTime =
            timestamp.toDate(); // Convert Timestamp to DateTime
        DateTime now = DateTime.now(); // Get current time
        Duration difference =
            now.difference(timestampDateTime); // Calculate difference

        print("Current time: $now");
        print("Timestamp time: $timestampDateTime");
        print("Difference in hours: ${difference.inHours}");

        if (difference.inHours >= 2) {
          // If the timestamp is older than 2 hours, fetch a new avatar
          print("Avatar is old, fetching a new one.");
          String? newAvatarUrl =
              await avatarService.fetchAvatarFromZalo(dienThoai);
          if (newAvatarUrl != null) {
            await avatarService.saveAvatarToFirebase(newAvatarUrl, dienThoai,
                maSinhVien); // Save new avatar to Firestore
            setState(() {
              setAvatarUrl(newAvatarUrl); // Update avatar URL
              setIsFetched(true);
              setIsLoading(false);
            });
          }
        } else {
          // Use the existing avatar
          print("Using existing avatar.");
          setState(() {
            setAvatarUrl(avatarUrl); // Use existing avatar
            setIsFetched(true);
            setIsLoading(false);
          });
        }
      } else {
        // If no avatar or timestamp, fetch a new avatar
        print("No avatar or timestamp, fetching a new avatar.");
        String? newAvatarUrl =
            await avatarService.fetchAvatarFromZalo(dienThoai);
        if (newAvatarUrl != null) {
          await avatarService.saveAvatarToFirebase(newAvatarUrl, dienThoai,
              maSinhVien); // Save new avatar to Firestore
          setState(() {
            setAvatarUrl(newAvatarUrl); // Update avatar URL
            setIsFetched(true);
            setIsLoading(false);
          });
        }
      }
    } else {
      // If no data in Firestore, fetch a new avatar
      print("No data in Firestore, fetching a new avatar.");
      String? newAvatarUrl = await avatarService.fetchAvatarFromZalo(dienThoai);
      if (newAvatarUrl != null) {
        await avatarService.saveAvatarToFirebase(newAvatarUrl, dienThoai,
            maSinhVien); // Save new avatar to Firestore
        setState(() {
          setAvatarUrl(newAvatarUrl); // Update avatar URL
          setIsFetched(true);
          setIsLoading(false);
        });
      }
    }
  } catch (e) {
    print("Error checking Firestore: $e");
    setIsLoading(false);
  }
}
