import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/include/config.dart';
import 'package:hpc_students/Screen/StudentMarket/studentMarketViewProduct.dart';
import 'package:hpc_students/Screen/StudentMarket/studentMarketAdd.dart';

class StudentMarketMyProductsScreen extends StatefulWidget {
  @override
  _StudentMarketMyProductsScreenState createState() =>
      _StudentMarketMyProductsScreenState();
}

class _StudentMarketMyProductsScreenState
    extends State<StudentMarketMyProductsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> productList = [];
  bool isLoading = true;
  String errorMessage = '';
  String _maSinhVien = '';
  int currentPage = 1;
  int totalPages = 1;
  late TabController _tabController;
  String? _currentStatus;

  // Số lượng sản phẩm theo trạng thái
  int totalSale = 0;
  int totalSold = 0;
  int totalCancel = 0;

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
              _currentStatus = 'sale';
              break;
            case 2:
              _currentStatus = 'sold';
              break;
            case 3:
              _currentStatus = 'cancel';
              break;
          }
          currentPage = 1;
          _fetchProducts();
        });
      }
    });
    _loadMaSinhVien();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMaSinhVien() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _maSinhVien = prefs.getString('maSinhVien') ?? '';
    });
    if (_maSinhVien.isNotEmpty) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final url = SpreadsheetAPI.studentmarket;

      final Map<String, String> requestBody = {
        'copecute': SpreadApiKey,
        'action': 'getProductsByMSSV',
        'mssv': _maSinhVien,
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
          productList = data['products'] ?? [];
          totalPages = data['totalPages'] ?? 1;
          currentPage = data['currentPage'] ?? 1;

          final statusSummary = data['statusSummary'] as Map<String, dynamic>;
          totalSale = statusSummary['sale'] ?? 0;
          totalSold = statusSummary['sold'] ?? 0;
          totalCancel = statusSummary['cancel'] ?? 0;

          isLoading = false;
        });
      } else if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            setState(() {
              productList = data['products'] ?? [];
              totalPages = data['totalPages'] ?? 1;
              currentPage = data['currentPage'] ?? 1;

              final statusSummary =
                  data['statusSummary'] as Map<String, dynamic>;
              totalSale = statusSummary['sale'] ?? 0;
              totalSold = statusSummary['sold'] ?? 0;
              totalCancel = statusSummary['cancel'] ?? 0;

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
      print('Error fetching products: $e');
      setState(() {
        errorMessage = 'Có lỗi xảy ra khi tải danh sách sản phẩm';
        isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      _fetchProducts();
    }
  }

  void _prevPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      _fetchProducts();
    }
  }

  void _goToFirstPage() {
    if (currentPage != 1) {
      setState(() {
        currentPage = 1;
      });
      _fetchProducts();
    }
  }

  void _goToLastPage() {
    if (currentPage != totalPages) {
      setState(() {
        currentPage = totalPages;
      });
      _fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sản phẩm của tôi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentMarketAddProductScreen(),
                ),
              );
              if (result == true) {
                _fetchProducts();
              }
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              child: Row(
                children: [
                  Text('Tất cả'),
                  if ((totalSale + totalSold + totalCancel) > 0) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${totalSale + totalSold + totalCancel}',
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
                children: [
                  Text('Đang bán'),
                  if (totalSale > 0) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalSale',
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
                children: [
                  Text('Đã bán'),
                  if (totalSold > 0) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalSold',
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
                children: [
                  Text('Đã hủy'),
                  if (totalCancel > 0) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalCancel',
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
        onRefresh: _fetchProducts,
        child: Stack(
          children: [
            isLoading && productList.isEmpty
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
                              onPressed: _fetchProducts,
                              child: Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : productList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Chưa có sản phẩm nào',
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
                                      final product = productList[index];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  StudentMarketViewProduct(
                                                productData: product,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Card(
                                          margin: EdgeInsets.only(bottom: 16),
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Ảnh sản phẩm
                                              Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(12),
                                                    bottomLeft:
                                                        Radius.circular(12),
                                                  ),
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      () {
                                                        try {
                                                          final imgJson = json
                                                              .decode(product[
                                                                  'IMG']);
                                                          return imgJson['1'] ??
                                                              '';
                                                        } catch (e) {
                                                          return product[
                                                                  'IMG'] ??
                                                              '';
                                                        }
                                                      }(),
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              // Thông tin sản phẩm
                                              Expanded(
                                                child: Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        product['NAME'],
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        '${product['Price']}đ',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: isDarkMode
                                                              ? Colors
                                                                  .greenAccent
                                                              : Colors
                                                                  .green[700],
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isDarkMode
                                                                  ? Colors.white
                                                                      .withOpacity(
                                                                          0.1)
                                                                  : Theme.of(
                                                                          context)
                                                                      .primaryColor
                                                                      .withOpacity(
                                                                          0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Text(
                                                              product['Category']
                                                                      [
                                                                      'NAME'] ??
                                                                  'Chưa phân loại',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Theme.of(
                                                                            context)
                                                                        .primaryColor,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: _getStatusColor(
                                                                  product[
                                                                      'Status']),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Text(
                                                              _getStatusText(
                                                                  product[
                                                                      'Status']),
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    childCount: productList.length,
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
            if (isLoading && productList.isNotEmpty)
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

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'sale':
        return Colors.blue;
      case 'sold':
        return Colors.green;
      case 'cancel':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Không xác định';
    switch (status.toLowerCase()) {
      case 'sale':
        return 'Đang bán';
      case 'sold':
        return 'Đã bán';
      case 'cancel':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }
}
