import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hpc_students/include/config.dart';
import 'package:http/io_client.dart';
import 'package:provider/provider.dart';
import 'package:hpc_students/include/cookie_provider.dart'; // Import CookieProvider
import 'package:html/parser.dart' as htmlParser; // Add this import
import 'guiYeuCau.dart'; // Import the new file

class TraCuuYeuCauScreen extends StatefulWidget {
  @override
  _TraCuuYeuCauScreenState createState() => _TraCuuYeuCauScreenState();
}

class _TraCuuYeuCauScreenState extends State<TraCuuYeuCauScreen> {
  List<Map<String, String>> _yeuCauData = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchData(_currentPage); // Load data on initialization
  }

  Future<void> _fetchData(int page) async {
    final String? cookie = Provider.of<CookieProvider>(context, listen: false)
        .getCookie(); // Get cookie
    final url = '$baseUrl/ThongBao/TinDaGui?page=$page';

    final ioClient = IOClient();

    try {
      final response = await ioClient.get(
        Uri.parse(url),
        headers: {
          'Cookie': cookie ?? '', // Include cookie in the request
        },
      );
      if (response.statusCode == 200) {
        print("Cookie: $cookie"); // Print the cookie value
        var document = htmlParser.parse(response.body);
        var rows =
            document.querySelectorAll("table tbody tr:not(.table-header)");
        _yeuCauData = rows.map((row) {
          var cells = row.querySelectorAll("td");
          return {
            'stt': cells[0].text.trim(),
            'tieuDe': cells[1].text.trim(),
            'nguoiNhan': cells[2].text.trim(),
            'ngayGui': cells[3].text.trim(),
            'hoanThanh': cells[4].text.trim(),
            'cbPhanHoi': cells[5].text.trim(),
          };
        }).toList();

        // Handle pagination
        var pagination = document.querySelector("#paginationTDG");
        _totalPages = pagination?.children.length ?? 1; // Get total pages

        setState(() {
          _isLoading = false; // Set loading to false
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false; // Set loading to false
      });
    } finally {
      ioClient.close();
    }
  }

  void _onPageChange(int page) {
    setState(() {
      _currentPage = page;
      _isLoading = true; // Set loading to true
    });
    _fetchData(page); // Fetch data for the new page
  }

  void _sendRequest() {
    final String? cookie = Provider.of<CookieProvider>(context, listen: false)
        .getCookie(); // Get cookie
    if (cookie != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              InAppWebViewScreen(cookie: cookie), // No changes needed here
        ),
      );
    } else {
      // Handle case where cookie is not available
      print("No cookie available");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tra Cứu Yêu Cầu'),
        actions: [
          IconButton(
            icon: Icon(Icons
                .drive_file_rename_outline_rounded), // Icon for the send request button
            onPressed: _sendRequest, // Call the send request function
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _yeuCauData.length,
              itemBuilder: (context, index) {
                var item = _yeuCauData[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('STT: ${item['stt']}'),
                        Text('Tiêu đề: ${item['tieuDe']}'),
                        Text('Người nhận: ${item['nguoiNhan']}'),
                        Text('Ngày gửi: ${item['ngayGui']}'),
                        Text('Hoàn thành: ${item['hoanThanh']}'),
                        Text('CB phản hồi: ${item['cbPhanHoi']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar:
          _totalPages > 1 // Check if total pages are greater than 1
              ? BottomNavigationBar(
                  items: List.generate(_totalPages, (index) {
                    return BottomNavigationBarItem(
                      icon: Icon(Icons.pageview),
                      label: '${index + 1}',
                    );
                  }),
                  currentIndex: _currentPage - 1,
                  onTap: (index) => _onPageChange(index + 1),
                )
              : null, // Set to null if not enough pages
    );
  }
}
