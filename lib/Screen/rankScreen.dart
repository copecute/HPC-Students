import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hpc_students/include/config.dart';

class RankScreen extends StatefulWidget {
  @override
  _RankScreenState createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  List<Map<String, dynamic>> _rankList = [];
  bool _isLoading = true;
  bool _isDataFetched = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cachedRankings');

    if (cachedData != null) {
      List<dynamic> jsonData = jsonDecode(cachedData);
      _rankList = List<Map<String, dynamic>>.from(
          jsonData.map((item) => Map<String, dynamic>.from(item)));
      setState(() {
        _isLoading = false;
        _isDataFetched = true;
      });
    } else {
      await _fetchRankings();
    }
  }

  Future<void> _fetchRankings() async {
    try {
      final url = SpreadsheetAPI.profiles;
      final body = {
        'copecute': SpreadApiKey,
        'action': 'rankTBC',
      };

      final response = await http.post(
        Uri.parse(url),
        body: body,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      print("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response data: $data");

        setState(() {
          _rankList =
              List<Map<String, dynamic>>.from(data['rank'].map((item) => {
                    'fullname': item['FullName'],
                    'TBC': item['TBC'],
                    'Avatar': item['Avatar'],
                  }));
          _isLoading = false;
          _isDataFetched = true;
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cachedRankings', jsonEncode(_rankList));
      } else if (response.statusCode == 302) {
        print("Redirected to: ${response.headers['location']}");
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            print("Response data after redirect: $data");

            setState(() {
              _rankList =
                  List<Map<String, dynamic>>.from(data['rank'].map((item) => {
                        'fullname': item['FullName'],
                        'TBC': item['TBC'],
                        'Avatar': item['Avatar'],
                      }));
              _isLoading = false;
              _isDataFetched = true;
            });

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('cachedRankings', jsonEncode(_rankList));
          }
        }
      } else {
        throw Exception('Failed to load rankings');
      }
    } catch (e) {
      print('Error fetching rankings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
      _isDataFetched = false;
    });
    await _fetchRankings();
  }

  Widget _buildRankTile(Map<String, dynamic> rankData, int index) {
    if (index == 0) {
      // Top 1
      return Card(
        margin: EdgeInsets.all(10),
        color: Colors.red[700],
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: rankData['Avatar'] != null
                ? NetworkImage(rankData['Avatar'])
                : AssetImage('assets/avatar.png') as ImageProvider,
            child: Text('🥇', style: TextStyle(fontSize: 24)),
            backgroundColor: Colors.amber[700],
          ),
          title: Text(
            rankData['fullname'],
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Điểm TBC tích luỹ: ${rankData['TBC']}',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      );
    } else if (index == 1) {
      // Top 2
      return Card(
        margin: EdgeInsets.all(10),
        color: Colors.green[300],
        child: ListTile(
          leading: CircleAvatar(
            child: Text('🥈', style: TextStyle(fontSize: 24)),
            backgroundColor: Colors.grey[700],
          ),
          title: Text(
            rankData['fullname'],
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Điểm TBC tích luỹ: ${rankData['TBC']}',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      );
    } else if (index == 2) {
      // Top 3
      return Card(
        margin: EdgeInsets.all(10),
        color: Colors.blueGrey[300],
        child: ListTile(
          leading: CircleAvatar(
            child: Text('🥉', style: TextStyle(fontSize: 24)),
            backgroundColor: Colors.brown[700],
          ),
          title: Text(
            rankData['fullname'],
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Điểm TBC tích luỹ: ${rankData['TBC']}',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      );
    } else {
      // Các vị trí khác
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Text('${index + 1}', style: TextStyle(fontSize: 16)),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700] // Màu tối cho theme tối
                : Colors.grey[300], // Màu sáng cho theme sáng
          ),
          title: Text(
            rankData['fullname'],
            style: TextStyle(fontSize: 20),
          ),
          subtitle: Text(
            'Điểm TBC tích luỹ: ${rankData['TBC']}',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bảng xếp hạng'),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData, // Call refreshData when pulled down
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _rankList.isEmpty
                ? Center(child: Text('Không có dữ liệu'))
                : ListView.builder(
                    itemCount: _rankList.length,
                    itemBuilder: (context, index) {
                      return _buildRankTile(_rankList[index], index);
                    },
                  ),
      ),
    );
  }
}
