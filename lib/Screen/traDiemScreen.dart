import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:provider/provider.dart';
import 'package:hpc_students/include/config.dart';
import 'package:hpc_students/include/cookie_provider.dart';
import 'package:hpc_students/Screen/loginScreen.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class TraDiemScreen extends StatefulWidget {
  @override
  _TraDiemScreenState createState() => _TraDiemScreenState();
}

class _TraDiemScreenState extends State<TraDiemScreen> {
  String? htmlResponse;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchScores();
  }

  Future<void> fetchScores() async {
    setState(() {
      isLoading = true;
    });

    String? cookie = Provider.of<CookieProvider>(context, listen: false).getCookie();
    if (cookie == null || cookie.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Bước 1: Gửi yêu cầu đến Index
    final urlIndex = Uri.parse("https://sinhvien.bachkhoahanoi.edu.vn/TraCuuDiem/Index");
    final responseIndex = await http.post(urlIndex, headers: {
      'Cookie': cookie,
    });

    if (responseIndex.statusCode == 200) {
      // Bước 2: Gửi yêu cầu lấy thông tin điểm
      final urlScore = Uri.parse("https://sinhvien.bachkhoahanoi.edu.vn/TraCuuDiem/ThongTinDiemSinhVien");
      final responseScore = await http.post(urlScore, headers: {
        'Cookie': cookie,
      });

      if (responseScore.statusCode == 200) {
        // Kiểm tra phản hồi
        if (responseScore.body.contains('Object moved to <a href="/">here</a>')) {
          // Phiên đã hết hạn, chuyển hướng về trang đăng nhập
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          // Hiển thị kết quả tra cứu điểm
          setState(() {
            htmlResponse = responseScore.body;
          });
        }
      } else {
        // Xử lý lỗi nếu yêu cầu không thành công
        setState(() {
          htmlResponse = 'Lỗi khi lấy thông tin điểm';
        });
      }
    } else {
      // Xử lý lỗi nếu yêu cầu không thành công
      setState(() {
        htmlResponse = 'Lỗi khi gửi yêu cầu Index';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tra cứu điểm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: htmlResponse != null
              ? HtmlWidget(htmlResponse!)
              : Text('Không có dữ liệu'),
        ),
      ),
    );
  }
}
