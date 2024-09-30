import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RankScreen extends StatefulWidget {
  @override
  _RankScreenState createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _rankList = [];
  bool _isLoading = true;
  bool _isDataFetched = false; // Add a flag to check if data is already fetched
  String? _selectedCategory; // Variable to store the selected category
  List<String> _categories = [
    'All',
    'Category 1',
    'Category 2'
  ]; // Example categories

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data on initialization
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cachedRankings'); // Load cached data

    if (cachedData != null) {
      // If cached data exists, parse it and update the UI
      List<dynamic> jsonData = jsonDecode(cachedData); // Decode JSON
      _rankList = List<Map<String, dynamic>>.from(jsonData.map((item) =>
          Map<String, dynamic>.from(
              item))); // Cast to List<Map<String, dynamic>>
      setState(() {
        _isLoading = false; // Set loading to false
        _isDataFetched = true; // Mark data as fetched
      });
    } else {
      // If no cached data, fetch from Firestore
      await _fetchRankings();
    }
  }

  Future<void> _fetchRankings() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('HPCRanks')
          .orderBy('TBC', descending: true)
          .limit(10) // so lượng người muốn hiển thị
          .get();

      setState(() {
        _rankList = snapshot.docs.map((doc) {
          return {
            'fullname': doc['fullname'],
            'TBC': doc['TBC'],
            'Trangthai': doc['Trangthai'],
          };
        }).toList();
        _isLoading = false;
        _isDataFetched = true; // Set the flag to true after fetching
      });

      // Cache the data
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'cachedRankings', jsonEncode(_rankList)); // Save to cache
    } catch (e) {
      print('Error fetching rankings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _isLoading = true; // Show loading state while fetching data
      _isDataFetched = false; // Mark data as not fetched
    });
    await _fetchRankings(); // Fetch data again
  }

  Widget _buildRankTile(Map<String, dynamic> rankData, int index) {
    if (index == 0) {
      // Top 1
      return Card(
        margin: EdgeInsets.all(10),
        color: Colors.red[700],
        child: ListTile(
          leading: CircleAvatar(
            child: Text('🥇', style: TextStyle(fontSize: 24)),
            backgroundColor: Colors.amber[700],
          ),
          title: Text(
            rankData['fullname'],
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'TBC: ${rankData['TBC']} | Trạng thái: ${rankData['Trangthai'] ? 'Đang học' : 'Ngừng học'}',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      );
    } else if (index == 1) {
      // Top 2
      return Card(
        margin: EdgeInsets.all(10),
        color: Colors.amber[300],
        child: ListTile(
          leading: CircleAvatar(
            child: Text('🥈', style: TextStyle(fontSize: 24)),
            backgroundColor: Colors.grey[700],
          ),
          title: Text(
            rankData['fullname'],
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'TBC: ${rankData['TBC']} | Trạng thái: ${rankData['Trangthai'] ? 'Đang học' : 'Ngừng học'}',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    } else if (index == 2) {
      // Top 3
      return Card(
        margin: EdgeInsets.all(10),
        color: Colors.brown[100],
        child: ListTile(
          leading: CircleAvatar(
            child: Text('🥉', style: TextStyle(fontSize: 24)),
            backgroundColor: Colors.brown[700],
          ),
          title: Text(
            rankData['fullname'],
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'TBC: ${rankData['TBC']} | Trạng thái: ${rankData['Trangthai'] ? 'Đang học' : 'Ngừng học'}',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    } else {
      // Các vị trí khác
      return Card(
        margin: EdgeInsets.all(10),
        child: ListTile(
          title: Text(
            rankData['fullname'],
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'TBC: ${rankData['TBC']} | Trạng thái: ${rankData['Trangthai'] ? 'Đang học' : 'Ngừng học'}',
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
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Open the drawer when the search icon is pressed
              Scaffold.of(context).openEndDrawer();
            },
          ),
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              // Open the drawer when the menu icon is pressed
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text(
                'Chọn chuyên mục',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            // Add your dropdown or other widgets here
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: _selectedCategory ?? 'All',
                items: _categories
                    .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    // Optionally, you can filter the rankings based on the selected category
                    // _fetchRankings(category: value);
                  });
                },
              ),
            ),
          ],
        ),
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
