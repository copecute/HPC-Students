import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/include/config.dart';

class LibraryOrderScreen extends StatefulWidget {
  @override
  _LibraryOrderScreenState createState() => _LibraryOrderScreenState();
}

class _LibraryOrderScreenState extends State<LibraryOrderScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> orders = [];
  bool isLoading = true;
  String errorMessage = '';
  int currentPage = 1;
  int totalPages = 1;
  late TabController _tabController;
  String? _currentStatus;

  // Số lượng đơn theo trạng thái
  int totalPending = 0;
  int totalBorrowing = 0;
  int totalReturned = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: 0,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _currentStatus = null;
              break;
            case 1:
              _currentStatus = 'Pending';
              break;
            case 2:
              _currentStatus = 'Borrowing';
              break;
            case 3:
              _currentStatus = 'Returned';
              break;
          }
          currentPage = 1;
          _fetchOrders();
        });
      }
    });
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final prefs = await SharedPreferences.getInstance();
      final mssv = prefs.getString('username');

      if (mssv == null) {
        setState(() {
          errorMessage = 'Vui lòng đăng nhập để xem sách đã mượn';
          isLoading = false;
        });
        return;
      }

      final url = SpreadsheetAPI.libraryBooks;

      final Map<String, String> requestBody = {
        'copecute': SpreadApiKey,
        'action': 'getBorrowing',
        'mssv': mssv,
        'page': currentPage.toString(),
      };

      if (_currentStatus != null) {
        requestBody['status'] = _currentStatus!;
      }

      final response = await http.post(
        Uri.parse(url),
        body: requestBody,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orders = data['orders'] ?? [];
          totalPages = data['totalPages'] ?? 1;
          currentPage = data['currentPage'] ?? 1;

          final statusSummary = data['statusSummary'] as Map<String, dynamic>;
          totalPending = statusSummary['pending'] ?? 0;
          totalBorrowing = statusSummary['borrowing'] ?? 0;
          totalReturned = statusSummary['returned'] ?? 0;

          isLoading = false;
        });
      } else if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            setState(() {
              orders = data['orders'] ?? [];
              totalPages = data['totalPages'] ?? 1;
              currentPage = data['currentPage'] ?? 1;

              final statusSummary =
                  data['statusSummary'] as Map<String, dynamic>;
              totalPending = statusSummary['pending'] ?? 0;
              totalBorrowing = statusSummary['borrowing'] ?? 0;
              totalReturned = statusSummary['returned'] ?? 0;

              isLoading = false;
            });
          }
        }
      } else {
        setState(() {
          errorMessage = 'Không thể kết nối đến server';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        errorMessage = 'Có lỗi xảy ra khi tải danh sách sách đã mượn';
        isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      _fetchOrders();
    }
  }

  void _prevPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      _fetchOrders();
    }
  }

  void _goToFirstPage() {
    if (currentPage != 1) {
      setState(() {
        currentPage = 1;
      });
      _fetchOrders();
    }
  }

  void _goToLastPage() {
    if (currentPage != totalPages) {
      setState(() {
        currentPage = totalPages;
      });
      _fetchOrders();
    }
  }

  String _getStatusText(dynamic status) {
    if (status == null || status.toString() == 'pending') return 'Chờ xử lý';
    switch (status.toString()) {
      case 'Borrowing':
        return 'Đang mượn';
      case 'Returned':
        return 'Đã trả';
      default:
        return 'Chờ xử lý';
    }
  }

  Color _getStatusColor(dynamic status) {
    if (status == null || status.toString() == 'pending') return Colors.orange;
    switch (status.toString()) {
      case 'Borrowing':
        return Colors.blue;
      case 'Returned':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Widget _buildOrderDetails(Map<String, dynamic> order) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final orderItems = order['ORDER'];
    final ordererInfo = order['OrdererInformation'];
    final note = order['Note'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin người mượn:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 16,
              color: isDarkMode ? Colors.white70 : null,
            ),
            SizedBox(width: 8),
            Text(
              ordererInfo['fullname'] ?? '',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              Icons.phone_outlined,
              size: 16,
              color: isDarkMode ? Colors.white70 : null,
            ),
            SizedBox(width: 8),
            Text(
              ordererInfo['phoneNumber'] ?? '',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        Text(
          'Sách đã mượn:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        ...orderItems.values.map((item) {
          final Map<String, dynamic> book = item as Map<String, dynamic>;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book['IMG'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['NAME'],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'Số lượng: ${book['Quantity']}',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white70
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        // Ghi chú
        if (note != null && note.isNotEmpty) ...[
          SizedBox(height: 16),
          Text(
            'Ghi chú:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.note_outlined,
                size: 16,
                color: isDarkMode ? Colors.white70 : null,
              ),
              SizedBox(width: 8),
              Text(
                note,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sách đã mượn',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tất cả'),
                  if ((totalPending + totalBorrowing + totalReturned) > 0) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${totalPending + totalBorrowing + totalReturned}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Chờ xử lý'),
                  if (totalPending > 0) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalPending',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Đang mượn'),
                  if (totalBorrowing > 0) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalBorrowing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Đã trả'),
                  if (totalReturned > 0) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalReturned',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: Stack(
          children: [
            isLoading && orders.isEmpty
                ? Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red[300]),
                            SizedBox(height: 16),
                            Text(
                              errorMessage,
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchOrders,
                              child: Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.library_books_outlined,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Chưa có sách nào được mượn',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.all(16),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final order = orders[index];
                                      return Card(
                                        margin: EdgeInsets.only(bottom: 16),
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Mã phiếu mượn #${order['STT']}',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                              order['Status'])
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      _getStatusText(
                                                          order['Status']),
                                                      style: TextStyle(
                                                        color: _getStatusColor(
                                                            order['Status']),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 16),
                                              _buildOrderDetails(order),
                                              Divider(height: 24),
                                              Text(
                                                'Thời gian: ${DateTime.parse(order['Timestamp']).toLocal().toString().substring(0, 16)}',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    childCount: orders.length,
                                  ),
                                ),
                              ),
                              if (totalPages > 1)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.first_page),
                                          onPressed: currentPage > 1
                                              ? _goToFirstPage
                                              : null,
                                          color: currentPage > 1
                                              ? isDarkMode
                                                  ? Colors.white
                                                  : Theme.of(context)
                                                      .primaryColor
                                              : Colors.grey,
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.chevron_left),
                                          onPressed: currentPage > 1
                                              ? _prevPage
                                              : null,
                                          color: currentPage > 1
                                              ? isDarkMode
                                                  ? Colors.white
                                                  : Theme.of(context)
                                                      .primaryColor
                                              : Colors.grey,
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            'Trang $currentPage/$totalPages',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.chevron_right),
                                          onPressed: currentPage < totalPages
                                              ? _nextPage
                                              : null,
                                          color: currentPage < totalPages
                                              ? isDarkMode
                                                  ? Colors.white
                                                  : Theme.of(context)
                                                      .primaryColor
                                              : Colors.grey,
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.last_page),
                                          onPressed: currentPage < totalPages
                                              ? _goToLastPage
                                              : null,
                                          color: currentPage < totalPages
                                              ? isDarkMode
                                                  ? Colors.white
                                                  : Theme.of(context)
                                                      .primaryColor
                                              : Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
            if (isLoading && orders.isNotEmpty)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
