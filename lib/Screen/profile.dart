import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:http/io_client.dart';
// Hide the functions

Future<void> saveAvatarToFirebase(
    String? avatarUrl, String dienThoai, String maSinhVien) async {
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    CollectionReference students =
        FirebaseFirestore.instance.collection('Students_Profile');

    try {
      DocumentSnapshot doc = await students.doc(maSinhVien).get();
      bool needsUpdate = false;

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['avatar'] != avatarUrl) needsUpdate = true;

        if (needsUpdate) {
          // Cập nhật dữ liệu nếu có thay đổi
          await students.doc(maSinhVien).update({
            'avatar': avatarUrl,
            'timestamp': FieldValue.serverTimestamp(), // Update timestamp
          });
          print("Cập nhật avatar lên Firebase: $avatarUrl");
          print("Mã sinh viên: $maSinhVien");
          print("Điện thoại: $dienThoai");
        } else {
          print("Avatar đã đúng, không cần cập nhật");
          print("Mã sinh viên: $maSinhVien");
          print("Điện thoại: $dienThoai");
        }
      } else {
        // Tạo mới dữ liệu nếu chưa tồn tại
        await students.doc(maSinhVien).set({
          'avatar': avatarUrl,
          'dienThoai': dienThoai,
          'timestamp': FieldValue.serverTimestamp(), // Save current timestamp
        });
        print("Tạo mới $maSinhVien và lưu avatar lên Firebase: $avatarUrl");
        print("Mã sinh viên: $maSinhVien");
        print("Điện thoại: $dienThoai");
      }
    } catch (e) {
      print('Lỗi khi lưu avatar lên Firebase: $e');
      print("Mã sinh viên: $maSinhVien");
      print("Điện thoại: $dienThoai");
    }
  }
}

Future<String?> fetchAvatarFromZalo(String dienThoai) async {
  final url = 'https://zalo.me/$dienThoai'; // Use dienThoai for the URL
  final HttpClient httpClient = HttpClient()
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

  final ioClient = IOClient(httpClient);

  try {
    final response = await ioClient.get(
      Uri.parse(url),
    );

    if (response.statusCode == 200) {
      print("$dienThoai đã get $url");
      String responseBody = response.body;

      // Extract the avatar URL from the response body
      RegExp regExp = RegExp(r'"avatar":"(.*?)"');
      Match? match = regExp.firstMatch(responseBody);
      return match != null
          ? match.group(1)
          : null; // Return the avatar URL or null
    } else {
      print("Failed to fetch avatar: ${response.statusCode}");
      return null; // Return null if the request fails
    }
  } catch (e) {
    print('Error fetching avatar: $e');
    return null; // Return null in case of an error
  } finally {
    ioClient.close();
  }
}

Future<String?> getAvatar(String dienThoai, String maSinhVien) async {
  CollectionReference students =
      FirebaseFirestore.instance.collection('Students_Profile');

  try {
    DocumentSnapshot doc = await students.doc(maSinhVien).get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String? avatarUrl = data['avatar'];
      Timestamp? timestamp = data['timestamp'];

      // Kiểm tra timestamp
      if (timestamp != null) {
        DateTime lastUpdated = timestamp.toDate();
        if (DateTime.now().difference(lastUpdated).inHours >= 2) {
          // Nếu timestamp cũ hơn 2 giờ, lấy avatar mới từ Zalo
          String? newAvatarUrl = await fetchAvatarFromZalo(dienThoai);
          if (newAvatarUrl != null) {
            // Cập nhật avatar mới vào Firebase
            await saveAvatarToFirebase(newAvatarUrl, dienThoai, maSinhVien);
            return newAvatarUrl; // Trả về avatar mới
          }
        } else {
          // Nếu không cũ hơn 2 giờ, trả về avatar hiện tại
          return avatarUrl;
        }
      }
    }
  } catch (e) {
    print('Lỗi khi lấy avatar: $e');
  }
  return null; // Trả về null nếu không có avatar
}
