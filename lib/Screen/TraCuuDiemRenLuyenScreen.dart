import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import '../include/cookie_provider.dart';
import '../include/config.dart';
import 'loginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class TraCuuDiemRenLuyenScreen extends StatefulWidget {
  @override
  _TraCuuDiemRenLuyenScreenState createState() =>
      _TraCuuDiemRenLuyenScreenState();
}

class _TraCuuDiemRenLuyenScreenState extends State<TraCuuDiemRenLuyenScreen> {
  String? htmlResponse;
  bool _isLoading = true;
  bool _isFetched = false; // Flag to check if data has been fetched

  @override
  void initState() {
    super.initState();
    _fetchData(); // Fetch data on initialization
  }

  Future<void> _fetchData() async {
    String? cookie =
        Provider.of<CookieProvider>(context, listen: false).getCookie();

    if (cookie == null || cookie.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LoginScreen()), // Redirect to login if no cookie
      );
      return;
    }

    final url = '$baseUrl/TraCuuDiem/DiemRenLuyen';
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    final ioClient = IOClient(httpClient);

    try {
      final response = await ioClient.get(
        Uri.parse(url),
        headers: {
          'Cookie': cookie, // Send cookie for authentication
        },
      );

      if (response.statusCode == 200) {
        var document = htmlParser.parse(response.body);
        var table = document.querySelector("div.news table.table-bordered");

        setState(() {
          htmlResponse = table?.outerHtml; // Store only the table HTML
          _isLoading = false; // Set loading to false
          _isFetched = true; // Mark data as fetched
        });
      } else {
        setState(() {
          htmlResponse = null;
          _isLoading = false; // Set loading to false
          _isFetched = true; // Mark data as fetched
        });
      }
    } catch (e) {
      setState(() {
        htmlResponse = null;
        _isLoading = false; // Set loading to false
        _isFetched = true; // Mark data as fetched
      });
    } finally {
      ioClient.close();
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _isLoading = true; // Show loading state while fetching data
      _isFetched = false; // Mark data as not fetched
    });
    await _fetchData(); // Fetch data again
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tra Cứu Điểm Rèn Luyện'),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData, // Call refreshData when pulled down
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator()) // Show loading indicator
            : htmlResponse == null
                ? Center(
                    child:
                        Text('Không có dữ liệu')) // When no data is available
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: HtmlWidget(
                        htmlResponse!, // Render the HTML response
                      ),
                    ),
                  ),
      ),
    );
  }
}
