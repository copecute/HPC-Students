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

class TraCuuDiemRenLuyenScreen extends StatefulWidget {
  @override
  _TraCuuDiemRenLuyenScreenState createState() =>
      _TraCuuDiemRenLuyenScreenState();
}

class _TraCuuDiemRenLuyenScreenState extends State<TraCuuDiemRenLuyenScreen> {
  List<Map<String, String>> _cardData = [];
  bool _isLoading = true;
  bool _isFetched = false; // Flag to check if data has been fetched

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data on initialization
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData =
        prefs.getString('cachedDiemRenLuyen'); // Load cached data

    if (cachedData != null) {
      // If cached data exists, parse it and update the UI
      List<dynamic> jsonData = jsonDecode(cachedData); // Decode JSON
      _cardData = List<Map<String, String>>.from(jsonData.map((item) =>
          Map<String, String>.from(item))); // Cast to List<Map<String, String>>
      setState(() {
        _isLoading = false; // Set loading to false
        _isFetched = true; // Mark data as fetched
      });
    } else {
      // If no cached data, fetch from the server
      await _fetchData();
    }
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
        var table = document.querySelector("div.row.fullwidth table");

        if (table != null) {
          var rows = table.querySelectorAll("tr");

          // Extract data from the table rows
          List<Map<String, String>> cardData = [];

          for (var row in rows.skip(1)) {
            var cells = row.querySelectorAll("td");
            if (cells.length >= 2) {
              cardData.add({
                'Tổng khóa': cells[0].text.trim(),
                'Xếp loại khóa': cells[1].text.trim(),
              });
            }
          }

          setState(() {
            _cardData = cardData; // Update the card data
            _isLoading = false; // Set loading to false
            _isFetched = true; // Mark data as fetched
          });

          // Cache the data
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'cachedDiemRenLuyen', jsonEncode(cardData)); // Save to cache
        } else {
          setState(() {
            _cardData = [];
            _isLoading = false; // Set loading to false
            _isFetched = true; // Mark data as fetched
          });
        }
      } else {
        setState(() {
          _cardData = [];
          _isLoading = false; // Set loading to false
          _isFetched = true; // Mark data as fetched
        });
      }
    } catch (e) {
      setState(() {
        _cardData = [];
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
            : _cardData.isEmpty
                ? Center(
                    child:
                        Text('Không có dữ liệu')) // When no data is available
                : ListView.builder(
                    itemCount: _cardData.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 4, // Card shadow effect
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Rounded corners
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tổng khóa: ${_cardData[index]['Tổng khóa']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Xếp loại khóa: ${_cardData[index]['Xếp loại khóa']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _cardData[index]['Xếp loại khóa'] ==
                                            'TB. Khá'
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
