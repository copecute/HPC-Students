import 'package:flutter/material.dart';
import 'package:hpc_students/Screen/StudentMarket/studentMarketViewProduct.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/include/config.dart';
import 'studentMarketMyProductsScreen.dart';

class StudentMarketScreen extends StatefulWidget {
  @override
  _StudentMarketScreenState createState() => _StudentMarketScreenState();
}

class _StudentMarketScreenState extends State<StudentMarketScreen> {
  List<dynamic> productList = [];
  bool isLoading = true;
  String errorMessage = '';
  String _hoTen = '';
  final TextEditingController _searchController = TextEditingController();
  int currentPage = 1;
  int totalPages = 1;

  List<dynamic> categories = [];
  String? selectedCategory;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const String CATEGORIES_CACHE_KEY = 'market_categories_cache';
  static const Duration CATEGORIES_CACHE_DURATION = Duration(days: 1);
  DateTime? _lastCategoriesFetch;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadCachedCategories();
    _fetchProducts();
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hoTen = prefs.getString('hoTen') ?? '';
    });
  }

  Future<void> _loadCachedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString(CATEGORIES_CACHE_KEY);
    final lastFetchTimeMillis = prefs.getInt('${CATEGORIES_CACHE_KEY}_time');

    if (categoriesJson != null && lastFetchTimeMillis != null) {
      final lastFetchTime =
          DateTime.fromMillisecondsSinceEpoch(lastFetchTimeMillis);
      if (DateTime.now().difference(lastFetchTime) <
          CATEGORIES_CACHE_DURATION) {
        setState(() {
          categories = json.decode(categoriesJson);
          _lastCategoriesFetch = lastFetchTime;
        });
        return;
      }
    }

    await _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final url = SpreadsheetAPI.studentmarket;

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': SpreadApiKey,
          'action': 'getProducts',
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categoriesData = data['categories'] ?? [];

        // Cache the categories
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            CATEGORIES_CACHE_KEY, json.encode(categoriesData));
        await prefs.setInt('${CATEGORIES_CACHE_KEY}_time',
            DateTime.now().millisecondsSinceEpoch);

        setState(() {
          categories = categoriesData;
          _lastCategoriesFetch = DateTime.now();
        });
      } else if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            final categoriesData = data['categories'] ?? [];

            // Cache the categories
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                CATEGORIES_CACHE_KEY, json.encode(categoriesData));
            await prefs.setInt('${CATEGORIES_CACHE_KEY}_time',
                DateTime.now().millisecondsSinceEpoch);

            setState(() {
              categories = categoriesData;
              _lastCategoriesFetch = DateTime.now();
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        isLoading = true;
      });

      final url = SpreadsheetAPI.studentmarket;

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': SpreadApiKey,
          'action': 'getProducts',
          'search': _searchController.text.trim(),
          'page': currentPage.toString(),
          if (selectedCategory != null) 'category': selectedCategory!,
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          productList = data['Products'] ?? [];
          totalPages = data['totalPages'] ?? 1;
          isLoading = false;
          errorMessage = '';
        });
      } else if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            setState(() {
              productList = data['Products'] ?? [];
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'Chợ sinh viên',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.inventory_2_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentMarketMyProductsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chợ sinh viên',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mua bán, trao đổi đồ cũ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('Chuyên mục',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Divider(),
            ListTile(
              title: Text('Tất cả sản phẩm'),
              selected: selectedCategory == null,
              onTap: () {
                setState(() {
                  selectedCategory = null;
                  currentPage = 1;
                });
                _fetchProducts();
                Navigator.pop(context);
              },
            ),
            ...categories.map((category) {
              return ListTile(
                title: Text(category['NAME']),
                selected: selectedCategory == category['STT'].toString(),
                onTap: () {
                  setState(() {
                    selectedCategory = category['STT'].toString();
                    currentPage = 1;
                  });
                  _fetchProducts();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào mừng $_hoTen đến với Chợ sinh viên! 🛍️',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm sản phẩm...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onSubmitted: (value) {
                            setState(() {
                              currentPage = 1;
                            });
                            _fetchProducts();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (errorMessage.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                if (productList.isEmpty && !isLoading)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Text('Không tìm thấy sản phẩm nào'),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 1200
                          ? 6
                          : MediaQuery.of(context).size.width > 900
                              ? 5
                              : MediaQuery.of(context).size.width > 600
                                  ? 4
                                  : MediaQuery.of(context).size.width > 400
                                      ? 2
                                      : 1,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = productList[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentMarketViewProduct(
                                  productData: product,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          () {
                                            try {
                                              final imgJson =
                                                  json.decode(product['IMG']);
                                              return imgJson['1'] ?? '';
                                            } catch (e) {
                                              return product['IMG'] ?? '';
                                            }
                                          }(),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            product['NAME'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '${product['Price']}đ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDarkMode
                                                  ? Colors.greenAccent
                                                  : Colors.green[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Colors.white
                                                      .withOpacity(0.1)
                                                  : Theme.of(context)
                                                      .primaryColor
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              product['Category']['NAME'] ??
                                                  'Chưa phân loại',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                        .primaryColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
