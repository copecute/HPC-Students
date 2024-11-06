import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/Screen/canteenShop/canteenViewProduct.dart';
import 'package:hpc_students/Screen/canteenShop/cart_provider.dart';
import 'package:hpc_students/Screen/canteenShop/cartScreen.dart';
import 'package:hpc_students/Screen/canteenShop/orderScreen.dart';
import 'package:hpc_students/include/config.dart';
import 'dart:async';

class CanteenScreen extends StatefulWidget {
  @override
  _CanteenScreenState createState() => _CanteenScreenState();
}

class _CanteenScreenState extends State<CanteenScreen> {
  List<dynamic> productList = [];
  bool isLoading = true;
  String errorMessage = '';
  int currentPage = 1;
  int totalPages = 1;
  final ScrollController _scrollController = ScrollController();
  String _hoTen = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    print("Initializing CanteenScreen...");
    _loadUserName();
    _fetchProducts();
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hoTen = prefs.getString('hoTen') ?? '';
    });
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        isLoading = true;
      });

      print("Fetching products for page: $currentPage");

      final url = SpreadsheetAPI.canteen;

      print('Fetching products from URL: $url');
      print('Request body: ${{
        'copecute': SpreadApiKey,
        'action': 'getProducts',
        'page': currentPage.toString(),
        'search': _searchController.text.trim(),
      }}');

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': SpreadApiKey,
          'action': 'getProducts',
          'page': currentPage.toString(),
          'search': _searchController.text.trim(),
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
          productList = data['products'] ?? [];
          totalPages = data['totalPages'] ?? 1;
          isLoading = false;
          errorMessage = '';
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
              productList = data['products'] ?? [];
              totalPages = data['totalPages'] ?? 1;
              isLoading = false;
              errorMessage = '';
            });
          } else {
            throw Exception('Failed to load data after redirect');
          }
        }
      } else {
        setState(() {
          errorMessage = 'Không có kết nối internet.';
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching products: $e");
      setState(() {
        errorMessage = 'Có lỗi xảy ra khi tải danh sách sản phẩm.';
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

  String _formatPrice(dynamic price) {
    if (price == null) return '0 đ';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      setState(() {
        currentPage = 1;
      });
      _fetchProducts();
    });
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
          'Căng tin HPC',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.receipt_long_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrderScreen()),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                },
              ),
              if (context.watch<CartProvider>().itemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '${context.watch<CartProvider>().itemCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle:
            isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào mừng $_hoTen đến với Căng tin HPC! 👋',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Khám phá các món ăn và đồ uống tuyệt vời của chúng tôi',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            if (_debounce?.isActive ?? false)
                              _debounce?.cancel();
                            setState(() {
                              currentPage = 1;
                            });
                            _fetchProducts();
                          },
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.orange.withOpacity(0.2)
                                    : Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.orange[300]
                                    : Colors.orange[800],
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Giao hàng nhanh chóng',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.orange[300]
                                            : Colors.orange[800],
                                      ),
                                    ),
                                    Text(
                                      'Đặt món và nhận trong vài phút',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.orange[300]
                                            : Colors.orange[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      childAspectRatio:
                          MediaQuery.of(context).size.width > 600 ? 0.8 : 0.75,
                      crossAxisSpacing:
                          MediaQuery.of(context).size.width * 0.04,
                      mainAxisSpacing: MediaQuery.of(context).size.width * 0.04,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = productList[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CanteenViewProduct(
                                  productData: product,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          product['IMG'] ?? '',
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: Icon(Icons.broken_image,
                                                    size: 40),
                                              ),
                                            );
                                          },
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.black
                                                      .withOpacity(0.7)
                                                  : Colors.black
                                                      .withOpacity(0.6),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.star,
                                                  size: 16,
                                                  color: Colors.amber,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '4.5',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['NAME']?.toString() ??
                                              'Chưa có tên',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Expanded(
                                          child: Text(
                                            product['Description']
                                                    ?.toString() ??
                                                '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatPrice(product['Price']),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                        .primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                        .primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  context
                                                      .read<CartProvider>()
                                                      .addItem(product);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Đã thêm vào giỏ hàng')),
                                                  );
                                                },
                                                child: Icon(
                                                  Icons.add_shopping_cart,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Theme.of(context)
                                                          .primaryColor
                                                      : Colors.white,
                                                  size: 20,
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.first_page),
                          onPressed: currentPage > 1 ? _goToFirstPage : null,
                          color: currentPage > 1
                              ? Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_left),
                          onPressed: currentPage > 1 ? _prevPage : null,
                          color: currentPage > 1
                              ? Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Trang $currentPage/$totalPages',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right),
                          onPressed:
                              currentPage < totalPages ? _nextPage : null,
                          color: currentPage < totalPages
                              ? Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        IconButton(
                          icon: Icon(Icons.last_page),
                          onPressed:
                              currentPage < totalPages ? _goToLastPage : null,
                          color: currentPage < totalPages
                              ? Theme.of(context).brightness == Brightness.dark
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
            if (isLoading)
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
