import 'package:shared_preferences/shared_preferences.dart';
import 'avatar_service.dart'; // Import the avatar service

Future<void> saveUserData(
    String hoTen,
    String dienThoai,
    String ngaySinh,
    String gioiTinh,
    String truongTHPT,
    String cmnd,
    String? avatarUrl,
    String maSinhVien) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('hoTen', hoTen);
  await prefs.setString('dienThoai', dienThoai);
  await prefs.setString('ngaySinh', ngaySinh);
  await prefs.setString('gioiTinh', gioiTinh);
  await prefs.setString('truongTHPT', truongTHPT);
  await prefs.setString('cmnd', cmnd);
  await prefs.setString('avatarUrl', avatarUrl ?? ''); // Lưu avatar URL

  // Save avatar URL to Firebase
  await saveAvatarToFirebase(avatarUrl, dienThoai, maSinhVien); // Updated line
  print("avatar: ${prefs.getString('avatarUrl')}");
}
