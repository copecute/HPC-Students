import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

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
          // Update data if there are changes
          await students.doc(maSinhVien).update({
            'avatar': avatarUrl,
            'timestamp': FieldValue.serverTimestamp(), // Update timestamp
          });
          print("Cập nhật avatar lên Firebase: $avatarUrl");
        } else {
          print("Avatar đã đúng, không cần cập nhật");
        }
      } else {
        // Create new data if it doesn't exist
        await students.doc(maSinhVien).set({
          'avatar': avatarUrl,
          'dienThoai': dienThoai,
          'timestamp': FieldValue.serverTimestamp(), // Save current timestamp
        });
        print("Tạo mới $maSinhVien và lưu avatar lên Firebase: $avatarUrl");
      }
    } catch (e) {
      print('Lỗi khi lưu avatar lên Firebase: $e');
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

Future<String?> getAvatar(String maSinhVien, String dienThoai) async {
  CollectionReference students =
      FirebaseFirestore.instance.collection('Students_Profile');

  try {
    DocumentSnapshot doc = await students.doc(maSinhVien).get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String? avatarUrl = data['avatar'];
      Timestamp? timestamp = data['timestamp'];

      // Check timestamp
      if (timestamp != null) {
        DateTime lastUpdated = timestamp.toDate();
        if (DateTime.now().difference(lastUpdated).inHours >= 2) {
          // If timestamp is older than 2 hours, fetch a new avatar
          String? newAvatarUrl = await fetchAvatarFromZalo(dienThoai);
          if (newAvatarUrl != null) {
            // Update the new avatar in Firebase
            await saveAvatarToFirebase(newAvatarUrl, dienThoai, maSinhVien);
            return newAvatarUrl; // Return the new avatar
          }
        } else {
          // If not older than 2 hours, return the existing avatar
          return avatarUrl;
        }
      }
    }
  } catch (e) {
    print('Lỗi khi lấy avatar: $e');
  }
  return null; // Return null if no avatar is found
}
