import 'dart:io';
import 'package:hpc_students/include/config.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/include/cookie_provider.dart';
import 'package:hpc_students/Screen/loginScreen.dart';
import 'avatar_service.dart' as avatarService;
import 'user_data_service.dart' as userService;

Future<void> loadData(
    BuildContext context,
    Function setState,
    String maSinhVien,
    String dienThoai,
    Function(String) setHoTen,
    Function(String) setDienThoai,
    Function(String?) setAvatarUrl,
    Function(bool) setIsLoading,
    Function(bool) setIsFetched,
    Function(String) setNgaySinh,
    Function(String) setGioiTinh,
    Function(String) setTruongTHPT,
    Function(String) setCmnd,
    Function(String) setTinh,
    Function(String) setHuyen,
    Function(String) setXa,
    Function(String) setChuyenNganh,
    Function(String) setHeDaoTao,
    Function(String) setKhoaHoc,
    Function(String) setNienKhoa,
    Function(String) setDanToc,
    Function(String) setQuocTich,
    Function(String) setTonGiao) async {
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
  maSinhVien = prefs.getString('maSinhVien') ?? '';

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
            '';
        String truongTHPT =
            document.getElementById("TruongTHPT")?.attributes['value'] ?? '';
        String cmnd =
            document.getElementById("CMND")?.attributes['value'] ?? '';

        String tinh = document
                .getElementById("ID_tinh_tt")
                ?.querySelector('option[selected]')
                ?.text ??
            '';
        String huyen = document
                .getElementById("ID_huyen_tt")
                ?.querySelector('option[selected]')
                ?.text ??
            '';
        String xa = document
                .getElementById("ID_xa_tt")
                ?.querySelector('option[selected]')
                ?.text ??
            '';

        String danToc = document
                .getElementById("ID_dan_toc")
                ?.querySelector('option[selected]')
                ?.text ??
            '';
        String quocTich = document
                .getElementById("ID_quoc_tich")
                ?.querySelector('option[selected]')
                ?.text ??
            '';
        String tonGiao = document
                .getElementById("Ton_giao")
                ?.querySelector('option[selected]')
                ?.text ??
            '';

        String chuyenNganh = '';
        String heDaoTao = '';
        String khoaHoc = '';
        String nienKhoa = '';

        for (var span in document.querySelectorAll('span.NoiDungHoSo')) {
          if (span.text.contains("Chuyên ngành:")) {
            chuyenNganh = span.nextElementSibling?.attributes['value'] ?? '';
          } else if (span.text.contains("Hệ đào tạo:")) {
            heDaoTao = span.nextElementSibling?.attributes['value'] ?? '';
          } else if (span.text.contains("Khóa học:")) {
            khoaHoc = span.nextElementSibling?.attributes['value'] ?? '';
          } else if (span.text.contains("Niên khóa:")) {
            nienKhoa = span.nextElementSibling?.attributes['value'] ?? '';
          }
        }

        setHoTen(hoTen);
        setDienThoai(dienThoai);
        setNgaySinh(ngaySinh);
        setGioiTinh(gioiTinh);
        setTruongTHPT(truongTHPT);
        setCmnd(cmnd);
        setTinh(tinh);
        setHuyen(huyen);
        setXa(xa);
        setChuyenNganh(chuyenNganh);
        setHeDaoTao(heDaoTao);
        setKhoaHoc(khoaHoc);
        setNienKhoa(nienKhoa);
        setDanToc(danToc);
        setQuocTich(quocTich);
        setTonGiao(tonGiao);

        // Save user data to API
        userService.saveUserData(
          maSinhVien,
          hoTen,
          dienThoai,
          ngaySinh,
          gioiTinh,
          cmnd,
          null, // avatarUrl will be set later
          chuyenNganh,
          heDaoTao,
          khoaHoc,
          nienKhoa,
          '', // tinChiTichLuy - to be implemented
          '', // tbc - to be implemented
        );

        setAvatarUrl(null);
        setIsLoading(false);
      });

      // Check and update avatar
      await checkAvatarFromAPI(context, maSinhVien, dienThoai, setState,
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

Future<void> checkAvatarFromAPI(
    BuildContext context,
    String maSinhVien,
    String dienThoai,
    Function setState,
    Function(String?) setAvatarUrl,
    Function(bool) setIsLoading,
    Function(bool) setIsFetched) async {
  print("Checking API for avatar... $maSinhVien");

  try {
    String? existingAvatar = await avatarService.getAvatarFromAPI(maSinhVien);

    if (existingAvatar != null && existingAvatar.isNotEmpty) {
      print("Avatar found in API.");
      setState(() {
        setAvatarUrl(existingAvatar);
        setIsFetched(true);
        setIsLoading(false);
      });
    } else {
      print("No avatar found, fetching from Zalo.");
      String? newAvatarUrl = await avatarService.fetchAvatarFromZalo(dienThoai);
      if (newAvatarUrl != null) {
        await avatarService.saveAvatarToAPI(newAvatarUrl, maSinhVien);
        setState(() {
          setAvatarUrl(newAvatarUrl);
          setIsFetched(true);
          setIsLoading(false);
        });
      }
    }
  } catch (e) {
    print("Error checking API: $e");
    setIsLoading(false);
  }
}
