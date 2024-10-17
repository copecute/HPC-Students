import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final CollectionReference students =
      FirebaseFirestore.instance.collection('HPCRanks');

  Future<void> saveOrUpdateStudent(String maSinhVien, String hoTen,
      String trangThai, String tbcTichLuy) async {
    try {
      DocumentSnapshot doc = await students.doc(maSinhVien).get();
      bool isTrangThaiActive = trangThai.contains("Đang học");

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool needsUpdate = false;

        if (data['fullname'] != hoTen) {
          needsUpdate = true;
          print(
              'Tên sinh viên đã thay đổi từ ${data['fullname']} thành $hoTen');
        }
        if (data['Trangthai'] != isTrangThaiActive) {
          needsUpdate = true;
          print(
              'Trạng thái đã thay đổi từ ${data['Trangthai']} thành $isTrangThaiActive');
        }
        if (data['TBC'] != tbcTichLuy) {
          needsUpdate = true;
          print('TBC đã thay đổi từ ${data['TBC']} thành $tbcTichLuy');
        }

        if (needsUpdate) {
          await students.doc(maSinhVien).update({
            'fullname': hoTen,
            'Trangthai': isTrangThaiActive,
            'TBC': tbcTichLuy,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('Cập nhật dữ liệu lên Firestore thành công');
        } else {
          print('Dữ liệu đã đúng, không cần cập nhật');
        }
      } else {
        await students.doc(maSinhVien).set({
          'fullname': hoTen,
          'Trangthai': isTrangThaiActive,
          'TBC': tbcTichLuy,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Tạo mới và lưu dữ liệu lên Firestore thành công');
      }
    } catch (e) {
      print('Lỗi khi lưu dữ liệu lên Firestore: $e');
    }
  }
}
