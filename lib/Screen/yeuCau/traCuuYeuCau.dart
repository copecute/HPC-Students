import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hpc_students/Screen/yeuCau/chiTietYeuCau.dart';
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
  final ScrollController _scrollController =
      ScrollController(); // Add a ScrollController

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
          var tieuDeElement =
              cells[1].querySelector("a"); // Get the <a> element
          var onclick =
              tieuDeElement?.attributes['onclick']; // Get the onclick attribute

          // Extract parameters from the onclick string
          final RegExp regex =
              RegExp(r"ChiTietHopThuDen\('(\d+)','(\d+)','(\d+)','(\w+)'\)");
          final match = regex.firstMatch(onclick ?? '');

          String id = match?.group(1) ?? ''; // Extract ID
          String gui = match?.group(2) ?? ''; // Extract gui
          String page = match?.group(3) ?? ''; // Extract page
          String hopthu = match?.group(4) ?? ''; // Extract hopthu

          return {
            'stt': cells[0].text.trim().isEmpty ? 'N/A' : cells[0].text.trim(),
            'tieuDe': cells[1].text.trim().isEmpty
                ? 'không có tiêu đề'
                : cells[1].text.trim(),
            'nguoiNhan':
                cells[2].text.trim().isEmpty ? 'N/A' : cells[2].text.trim(),
            'ngayGui':
                cells[3].text.trim().isEmpty ? 'N/A' : cells[3].text.trim(),
            'hoanThanh': cells[4].text.trim().isEmpty
                ? 'Đã tiếp nhận'
                : cells[4].text.trim(),
            'cbPhanHoi': cells[5].text.trim().isEmpty
                ? 'Đang chờ'
                : cells[5].text.trim(),
            'id': id, // Add extracted ID
            'gui': gui, // Add extracted gui
            'page': page, // Add extracted page
            'hopthu': hopthu, // Add extracted hopthu
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
    _scrollController.animateTo(
      // Scroll to the top
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
      body: ListView.builder(
        controller: _scrollController, // Assign the ScrollController
        itemCount: _yeuCauData.length + 1, // Add one for the pagination
        itemBuilder: (context, index) {
          if (index < _yeuCauData.length) {
            var item = _yeuCauData[index];
            return GestureDetector(
              onTap: () {
                // Use the extracted values directly
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChiTietYeuCauScreen(
                      id: item['id'] ?? '', // Use the extracted ID
                      gui: item['gui'] ?? '2', // Use the extracted gui
                      page: item['page'] ?? '1', // Use the extracted page
                      hopthu: item['hopthu'] ??
                          'TinGuiDi', // Use the extracted hopthu
                    ),
                  ),
                );
              },
              child: Card(
                margin: EdgeInsets.all(8.0),
                elevation: 4, // Add elevation for shadow effect
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Increased padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* Text(
                        'STT: ${item['stt']}',
                        style: TextStyle(
                          fontSize: 16, // Increased font size
                          fontWeight: FontWeight.bold, // Bold text
                        ),
                      ),
                      SizedBox(height: 8), // Space between text
                      */
                      Text(
                        '${item['tieuDe']}',
                        style: TextStyle(
                          fontSize: 20, // Increased font size
                          fontWeight: FontWeight.bold, // Bold text
                        ),
                      ),
                      SizedBox(height: 8), // Space between text
                      Text(
                        '${item['ngayGui']}',
                        style: TextStyle(
                          fontSize: 16, // Increased font size
                          fontWeight: FontWeight.normal, // Normal text
                        ),
                      ),
                      SizedBox(height: 8), // Space between text
                      Text(
                        'Người nhận: ${item['nguoiNhan']}',
                        style: TextStyle(
                          fontSize: 16, // Increased font size
                          fontWeight: FontWeight.normal, // Normal text
                        ),
                      ),
                      SizedBox(height: 8), // Space between text
                      Text(
                        'Trạng thái: ${item['hoanThanh']}',
                        style: TextStyle(
                          fontSize: 16, // Increased font size
                          fontWeight: FontWeight.normal, // Normal text
                        ),
                      ),
                      SizedBox(height: 8), // Space between text
                      Text(
                        'CB phản hồi: ${item['cbPhanHoi']}',
                        style: TextStyle(
                          fontSize: 16, // Increased font size
                          fontWeight: FontWeight.normal, // Normal text
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return _totalPages > 1 // Check if total pages are greater than 1
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1
                            ? () => _onPageChange(_currentPage - 1)
                            : null,
                      ),
                      Text('Trang $_currentPage tổng $_totalPages'),
                      IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed: _currentPage < _totalPages
                            ? () => _onPageChange(_currentPage + 1)
                            : null,
                      ),
                    ],
                  )
                : SizedBox
                    .shrink(); // Return an empty widget if not enough pages
          }
        },
      ),
    );
  }
}
