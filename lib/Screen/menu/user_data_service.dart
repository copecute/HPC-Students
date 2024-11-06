import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/include/config.dart';

Future<void> saveUserData(
    String maSinhVien,
    String hoTen,
    String dienThoai,
    String ngaySinh,
    String gioiTinh,
    String cmnd,
    String? avatarUrl,
    String chuyenNganh,
    String heDaoTao,
    String khoaHoc,
    String nienKhoa,
    String tinChiTichLuy,
    String tbc) async {
  // Save to SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('hoTen', hoTen);
  await prefs.setString('dienThoai', dienThoai);
  await prefs.setString('ngaySinh', ngaySinh);
  await prefs.setString('gioiTinh', gioiTinh);
  await prefs.setString('cmnd', cmnd);
  await prefs.setString('avatarUrl', avatarUrl ?? '');
  await prefs.setString('chuyenNganh', chuyenNganh);
  await prefs.setString('heDaoTao', heDaoTao);
  await prefs.setString('khoaHoc', khoaHoc);
  await prefs.setString('nienKhoa', nienKhoa);
  await prefs.setString('tinChiTichLuy', tinChiTichLuy);
  await prefs.setString('tbc', tbc);

  // Save to API
  final url = Uri.parse('${SpreadsheetAPI.profiles}');

  final Map<String, String> body = {
    'copecute': SpreadApiKey,
    'action': 'updateProfile',
    'mssv': maSinhVien,
    'fullName': hoTen,
    'avatar': avatarUrl ?? '',
    'phoneNumber': dienThoai,
    'birthday': ngaySinh,
    'sex': gioiTinh,
    'cccd': cmnd,
    'major': chuyenNganh,
    'trainingSystem': heDaoTao,
    'course': khoaHoc,
    'schoolYear': nienKhoa,
    'tinChiTichLuy': tinChiTichLuy,
    'tbc': tbc,
    'tbctimestamp': DateTime.now().toIso8601String(),
  };

  try {
    final response = await http.post(
      url,
      body: body,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 302) {
      if (response.statusCode == 302) {
        String? redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.post(
            Uri.parse(redirectUrl),
            body: body,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          );
          print("79. Redirect response status: ${redirectResponse.statusCode}");
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            if (data['success'] == true) {
              print("Successfully updated user data after redirect");
            } else {
              print("Failed to update after redirect: ${data['error']}");
            }
          }
        }
      } else {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print("Successfully updated user data");
        } else {
          print("Failed to update: ${data['error']}");
        }
      }
    } else {
      print("Failed to update user data: ${response.statusCode}");
      print("Response body: ${response.body}");
    }
  } catch (e) {
    print('Error saving user data to API: $e');
  }
}

Future<Map<String, dynamic>?> getUserData(String maSinhVien) async {
  final url = Uri.parse('${SpreadsheetAPI.profiles}');

  final Map<String, String> body = {
    'copecute': SpreadApiKey,
    'action': 'getProfile',
    'mssv': maSinhVien,
  };

  try {
    final response = await http.post(
      url,
      body: body,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 302) {
      if (response.statusCode == 302) {
        String? redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.post(
            Uri.parse(redirectUrl),
            body: body,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          );
          if (redirectResponse.statusCode == 200) {
            return json.decode(redirectResponse.body);
          }
        }
      } else {
        return json.decode(response.body);
      }
    } else {
      print("Failed to get user data: ${response.statusCode}");
      print("Response body: ${response.body}");
    }
  } catch (e) {
    print('Error getting user data from API: $e');
  }
  return null;
}
