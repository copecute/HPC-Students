import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class TraCuuRaVao extends StatefulWidget {
  @override
  _TraCuuRaVaoState createState() => _TraCuuRaVaoState();
}

class _TraCuuRaVaoState extends State<TraCuuRaVao> {
  String nfcData = "";
  String message = "Đặt thẻ lên đây..."; // Thông báo hiện tại
  String imagePath = 'assets/AccessControl/Parking.svg'; // Hình ảnh hiện tại
  bool isLoading = false;
  bool isNfcActive = true;

  @override
  void initState() {
    super.initState();
    _startNfcListening();
  }

  void _startNfcListening() async {
    if (!isNfcActive) return;

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      if (!isNfcActive) return;

      setState(() {
        isLoading = true; // Bắt đầu loading
      });

      String nfcData = tag.data.toString();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String maSV = prefs.getString('username') ?? "";

      DocumentReference docRef =
          FirebaseFirestore.instance.collection('AccessControl').doc(maSV);
      DocumentSnapshot docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        await docRef.set({
          'IO': true,
          'data': nfcData,
          'maSV': maSV,
        });
        _updateUI("Đỗ xe thành công", 'assets/AccessControl/Parked.svg');
      } else {
        String existingData = docSnapshot['data'];
        bool currentIO = docSnapshot['IO'];

        if (existingData == nfcData) {
          await docRef.update({'IO': !currentIO});
          _updateUI(
              currentIO ? "Lấy xe thành công" : "Đỗ xe thành công",
              currentIO
                  ? 'assets/AccessControl/GetCarSuccessfully.svg'
                  : 'assets/AccessControl/Parked.svg');
        } else {
          if (!currentIO) {
            await docRef.update({
              'data': nfcData,
              'IO': true,
            });
            _updateUI("Đỗ xe thành công", 'assets/AccessControl/Parked.svg');
          } else {
            _updateUI("Thẻ không trùng khớp",
                'assets/AccessControl/ParkingAccessDenied.svg');
          }
        }
      }

      setState(() {
        isLoading = false;
        isNfcActive = true;
      });
      NfcManager.instance.stopSession();
      _startNfcListening();
    });
  }

  void _updateUI(String newMessage, String newImagePath) {
    setState(() {
      message = newMessage;
      imagePath = newImagePath;
      isNfcActive = false; // Ngăn chặn lắng nghe NFC khi cập nhật UI
    });
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kiểm soát truy cập")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isLoading
                      ? CircularProgressIndicator()
                      : Column(
                          children: [
                            SvgPicture.asset(imagePath),
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
