import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/include/config.dart';
import 'package:hpc_students/Screen/LibraryBooks/libraryViewBook.dart';
import 'package:provider/provider.dart';
import 'package:hpc_students/Screen/LibraryBooks/library_cart_provider.dart';
import 'package:hpc_students/Screen/LibraryBooks/library_cart_screen.dart';
import 'package:hpc_students/Screen/LibraryBooks/library_order_screen.dart';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<dynamic> bookList = [];
  List<dynamic> categories = [];
  bool isLoading = true;
  String errorMessage = '';
  String _hoTen = '';
  final TextEditingController _searchController = TextEditingController();
  String? selectedCategory;
  int currentPage = 1;
  int totalPages = 1;

  static const String CATEGORIES_CACHE_KEY = 'library_categories_cache';
  static const Duration CATEGORIES_CACHE_DURATION = Duration(days: 1);
  DateTime? _lastCategoriesFetch;

  // Add GlobalKey for Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadCachedCategories();
    _fetchBooks();
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
      final url = SpreadsheetAPI.libraryBooks;

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': SpreadApiKey,
          'action': 'getBooks',
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

  Future<void> _fetchBooks() async {
    try {
      setState(() {
        isLoading = true;
      });

      final url = SpreadsheetAPI.libraryBooks;

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': SpreadApiKey,
          'action': 'getBooks',
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
          bookList = data['Books'] ?? [];
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
              bookList = data['Books'] ?? [];
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
      print("Error fetching books: $e");
      setState(() {
        errorMessage = 'Có lỗi xảy ra khi tải danh sách sách.';
        isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      _fetchBooks();
    }
  }

  void _prevPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      _fetchBooks();
    }
  }

  void _goToFirstPage() {
    if (currentPage != 1) {
      setState(() {
        currentPage = 1;
      });
      _fetchBooks();
    }
  }

  void _goToLastPage() {
    if (currentPage != totalPages) {
      setState(() {
        currentPage = totalPages;
      });
      _fetchBooks();
    }
  }

  Future<void> _clearCategoriesCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(CATEGORIES_CACHE_KEY);
    await prefs.remove('${CATEGORIES_CACHE_KEY}_time');
    await _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey, // Add key to Scaffold
      appBar: AppBar(
        title: Text(
          'Thư viện HPC',
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
                MaterialPageRoute(builder: (context) => LibraryOrderScreen()),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.shopping_basket,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LibraryCartScreen()),
                  );
                },
              ),
              if (context.watch<LibraryCartProvider>().itemCount > 0)
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
                      '${context.watch<LibraryCartProvider>().itemCount}',
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
                    'Thư viện HPC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Thư viện trường Cao đẳng Công nghệ Bách khoa Hà Nội',
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
              title: Text('Tất cả sách'),
              selected: selectedCategory == null,
              onTap: () {
                setState(() {
                  selectedCategory = null;
                  currentPage = 1;
                });
                _fetchBooks();
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
                  _fetchBooks();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBooks,
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
                          'Chào mừng $_hoTen đến với Thư viện HPC! 📚',
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
                            hintText: 'Tìm kiếm sách...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onSubmitted: (value) {
                            setState(() {
                              currentPage = 1;
                            });
                            _fetchBooks();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 1200
                          ? 6 // Extra large screens
                          : MediaQuery.of(context).size.width > 900
                              ? 5 // Large screens
                              : MediaQuery.of(context).size.width > 600
                                  ? 4 // Medium screens
                                  : MediaQuery.of(context).size.width > 400
                                      ? 2 // Small screens
                                      : 1, // Extra small screens
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = bookList[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LibraryViewBook(
                                  bookData: book,
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
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                          image: DecorationImage(
                                            image: NetworkImage(book['IMG']),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            book['Category']['NAME'],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            book['NAME'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Flexible(
                                          child: Text(
                                            book['Description'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
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
                      childCount: bookList.length,
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
