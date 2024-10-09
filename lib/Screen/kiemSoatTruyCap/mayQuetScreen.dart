import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class MayQuetScreen extends StatefulWidget {
  @override
  _MayQuetScreenState createState() => _MayQuetScreenState();
}

class _MayQuetScreenState extends State<MayQuetScreen> {
  String nfcData = "";
  String message = "Đặt thẻ lên đây..."; // Thông báo hiện tại
  String imagePath = 'assets/AccessControl/Parking.svg'; // Hình ảnh hiện tại
  bool isLoading = false;
  bool isNfcActive = true;
  Timer? _nfcTimer; // Timer to manage NFC reading delay

  @override
  void initState() {
    super.initState();
    _startNfcListening();
  }

  void _startNfcListening() async {
    if (!isNfcActive) return;

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      if (!isNfcActive) return;

      // Check if the timer is active
      if (_nfcTimer?.isActive ?? false) return;

      setState(() {
        isLoading = true; // Bắt đầu loading
      });

      String nfcData = tag.data.toString();
      print("NFC Data: $nfcData"); // Print the NFC data for debugging

      // Extract relevant data from nfcData
      Map<String, dynamic> parsedData = _extractRelevantData(nfcData);
      String formattedData =
          parsedData.toString(); // Convert to string for Firestore

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String maSV = prefs.getString('username') ?? "";

      DocumentReference docRef =
          FirebaseFirestore.instance.collection('AccessControl').doc(maSV);
      DocumentSnapshot docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        await docRef.set({
          'IO': true,
          'data':
              _formatDataAsString(parsedData), // Use the formatted string data
          'timestamp': DateTime.now().toIso8601String(), // Add timestamp
          'maSV': maSV,
        });
        _updateUI("Đỗ xe thành công", 'assets/AccessControl/Parked.svg');
      } else {
        String existingData = docSnapshot['data'];
        bool currentIO = docSnapshot['IO'];

        if (existingData == formattedData) {
          await docRef.update({
            'IO': !currentIO,
            'timestamp': DateTime.now()
                .toIso8601String(), // Update timestamp on successful retrieval
          });
          _updateUI(
              currentIO ? "Lấy xe thành công" : "Đỗ xe thành công",
              currentIO
                  ? 'assets/AccessControl/GetCarSuccessfully.svg'
                  : 'assets/AccessControl/Parked.svg');
        } else {
          if (!currentIO) {
            await docRef.update({
              'data': formattedData,
              'IO': true,
              'timestamp': DateTime.now()
                  .toIso8601String(), // Update timestamp on successful parking
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

      // Start the timer for 5 seconds
      _nfcTimer = Timer(Duration(seconds: 5), () {
        _startNfcListening(); // Restart NFC listening after delay
      });
    });
  }

  Map<String, dynamic> _extractRelevantData(String nfcData) {
    // Extract relevant fields from the nfcData string
    // Assuming nfcData is formatted as a string with specific patterns

    // Use regular expressions or string manipulation to extract the required fields
    RegExp identifierRegExp = RegExp(r'identifier:\s*\[(.*?)\]');
    RegExp historicalBytesRegExp = RegExp(r'historicalBytes:\s*\[(.*?)\]');
    RegExp atqaRegExp = RegExp(r'atqa:\s*\[(.*?)\]');

    String identifier = identifierRegExp.firstMatch(nfcData)?.group(1) ?? '';
    String historicalBytes =
        historicalBytesRegExp.firstMatch(nfcData)?.group(1) ?? '';
    String atqa = atqaRegExp.firstMatch(nfcData)?.group(1) ?? '';

    // Convert extracted strings to appropriate types
    List<int> identifierList =
        identifier.split(',').map((e) => int.parse(e.trim())).toList();
    List<int> historicalBytesList =
        historicalBytes.split(',').map((e) => int.parse(e.trim())).toList();
    List<int> atqaList =
        atqa.split(',').map((e) => int.parse(e.trim())).toList();

    // Return the relevant fields as a Map
    return {
      'identifier': identifierList,
      'historicalBytes': historicalBytesList,
      'atqa': atqaList,
    };
  }

  String _formatDataAsString(Map<String, dynamic> parsedData) {
    return '{identifier: ${parsedData['identifier']}, historicalBytes: ${parsedData['historicalBytes']}, atqa: ${parsedData['atqa']}}';
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
    _nfcTimer?.cancel(); // Cancel the timer if active
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Máy quét - kiểm soát truy cập")),
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
