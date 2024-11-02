import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/include/config.dart';

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String errorMessage = '';
  int currentPage = 1;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
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
          errorMessage = 'Vui lòng đăng nhập để xem đơn hàng';
          isLoading = false;
        });
        return;
      }

      final url =
          'https://script.google.com/macros/s/AKfycbwLIYesYJgBbpOFWhCPxfpMSxnFrZZSbv9iMorkPyG0b8HkRKv6RLpqlsVrkEk5vGoh/exec';

      print('Fetching orders from URL: $url');
      print('Request body: ${{
        'copecute': 'MIiwxJTx8h3a3HLYvpYpWXsywFH71f5jYP1IQo8AMUwmZr9H7y',
        'action': 'getOrders',
        'mssv': mssv,
        'page': currentPage.toString()
      }}');

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': 'MIiwxJTx8h3a3HLYvpYpWXsywFH71f5jYP1IQo8AMUwmZr9H7y',
          'action': 'getOrders',
          'mssv': mssv,
          'page': currentPage.toString(),
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      print("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response data: $data");

        setState(() {
          orders = data['orders'] ?? [];
          totalPages = data['totalPages'] ?? 1;
          currentPage = data['currentPage'] ?? 1;
          isLoading = false;
        });
      } else if (response.statusCode == 302) {
        print("Redirected to: ${response.headers['location']}");
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            print("Response data after redirect: $data");

            setState(() {
              orders = data['orders'] ?? [];
              totalPages = data['totalPages'] ?? 1;
              currentPage = data['currentPage'] ?? 1;
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
        errorMessage = 'Có lỗi xảy ra khi tải đơn hàng';
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

  String _formatPrice(dynamic price) {
    if (price == null) return '0 đ';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
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
        // Thông tin người đặt
        Text(
          'Thông tin người đặt:',
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

        // Chi tiết đơn hàng
        Text(
          'Chi tiết đơn hàng:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        ...orderItems.values.map((item) {
          final Map<String, dynamic> product = item as Map<String, dynamic>;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product['IMG'],
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
                        product['NAME'],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '${_formatPrice(product['Price'])} x ${product['Quantity']}',
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
                Text(
                  _formatPrice(product['Price'] * product['Quantity']),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
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

    SystemChrome.setSystemUIOverlayStyle(
      isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Đơn hàng của tôi',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle:
            isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Chưa có đơn hàng nào',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.width * 0.04),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final order = orders[index];
                                      return Card(
                                        margin: EdgeInsets.only(
                                            bottom: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.02),
                                        child: Padding(
                                          padding: EdgeInsets.all(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.04),
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
                                                    'Đơn hàng #${order['STT']}',
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
                                                              order['Status'] ??
                                                                  '')
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      _getStatusText(
                                                          order['Status'] ??
                                                              ''),
                                                      style: TextStyle(
                                                        color: _getStatusColor(
                                                            order['Status'] ??
                                                                ''),
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
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Tổng tiền:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatPrice(
                                                        order['UnitPrice']),
                                                    style: TextStyle(
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Theme.of(context)
                                                              .primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
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
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.first_page),
                                        onPressed: currentPage > 1
                                            ? _goToFirstPage
                                            : null,
                                        color: currentPage > 1
                                            ? Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Theme.of(context).primaryColor
                                            : Colors.grey,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.chevron_left),
                                        onPressed:
                                            currentPage > 1 ? _prevPage : null,
                                        color: currentPage > 1
                                            ? Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Theme.of(context).primaryColor
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
                                            ? Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Theme.of(context).primaryColor
                                            : Colors.grey,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.last_page),
                                        onPressed: currentPage < totalPages
                                            ? _goToLastPage
                                            : null,
                                        color: currentPage < totalPages
                                            ? Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Theme.of(context).primaryColor
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
