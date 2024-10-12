import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import thư viện SVG
import 'package:intl/intl.dart'; // Import thư viện intl
import 'mayQuetScreen.dart'; // Import MayQuetScreen

class TraCuuTruyCapScreen extends StatefulWidget {
  @override
  _TraCuuTruyCapScreenState createState() => _TraCuuTruyCapScreenState();
}

class _TraCuuTruyCapScreenState extends State<TraCuuTruyCapScreen> {
  String maSV = "";
  Map<String, dynamic>? userData;
  bool isLoading = true; // Add a loading state variable

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true; // Set loading to true before fetching data
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    maSV = prefs.getString('username') ?? "";

    DocumentReference docRef =
        FirebaseFirestore.instance.collection('AccessControl').doc(maSV);
    DocumentSnapshot docSnapshot = await docRef.get();

    setState(() {
      isLoading = false; // Set loading to false after fetching data
      if (docSnapshot.exists) {
        userData = docSnapshot.data() as Map<String, dynamic>;
      } else {
        userData = null; // Không có dữ liệu
      }
    });
  }

  String _formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat('HH:mm:ss dd/MM/yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tra cứu truy cập"),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt), // Biểu tượng máy quét
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MayQuetScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserData, // Gọi lại hàm lấy dữ liệu khi refresh
        child: Center(
          child: isLoading // Check if loading
              ? CircularProgressIndicator() // Show loading indicator
              : userData == null
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/AccessControl/Parking.svg',
                          ),
                          SizedBox(
                              height:
                                  20), // Khoảng cách giữa hình ảnh và văn bản
                          Text(
                            "Không có thông tin đỗ xe.",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              height:
                                  20), // Khoảng cách giữa hình ảnh và văn bản
                          Text(
                              "Mã sinh viên: ${userData?['maSV'] ?? 'N/A'}", // Add null check
                              style: TextStyle(fontSize: 20)),
                          Text(
                              "Trạng thái: ${userData?['IO'] != null ? (userData!['IO'] ? 'Đang đỗ xe' : 'Đã lấy xe') : 'N/A'}", // Add null check
                              style: TextStyle(fontSize: 20)),
                          Text(
                              "Thời gian: ${userData?['timestamp'] != null ? _formatTimestamp(userData!['timestamp']) : 'N/A'}", // Add null check
                              style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
