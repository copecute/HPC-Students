import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'blogDetailScreen.dart';
import 'package:hpc_students/include/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Add this import for rootBundle

class BlogScreen extends StatefulWidget {
  @override
  _BlogScreenState createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  List<XmlElement> _posts = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPosts = 0;
  final int _postsPerPage = 10;
  TextEditingController _searchController = TextEditingController();
  List<XmlElement> _filteredPosts = [];
  int _totalPages = 0;
  List<String> _categories = [];
  String? _selectedCategory; // Variable to store the selected category
  String _defaultImage =
      'https://blogger.googleusercontent.com/img/a/AVvXsEiYorgTwvKTp7bjT_1O6HrAl2K4vYEcimlyzfv-0UNwF8x_ov7avCHuZoVdg6K-u2GhL7bOUOmL9DSC4YiBQOF82bmOxYFhmzcd_S15-AikwfL83vmYIAPuBtCPGeRsRfAiVw0REdGk-GZltwNDSWuKC-WFGvU1WwUCASD8CynnsGpOH91geRjUW2rVmC0=w220-h146-p-k-no-nu'; // Default image path

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data on initialization
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cachedBlogPosts'); // Load cached data
    String? cachedCategories =
        prefs.getString('cachedCategories'); // Load cached categories

    if (cachedData != null) {
      // If cached data exists, parse it and update the UI
      final document = XmlDocument.parse(cachedData);
      final entries = document.findAllElements('entry');
      setState(() {
        _posts = entries.toList();
        _totalPosts = int.parse(
            document.findAllElements('openSearch:totalResults').first.text);
        _filteredPosts = _posts;
        _totalPages = (_totalPosts / _postsPerPage).ceil();
        _isLoading = false; // Set loading to false
      });
    } else {
      // If no cached data, fetch from the server
      await _fetchBlogPosts();
    }

    if (cachedCategories != null) {
      // If cached categories exist, parse and set them
      setState(() {
        _categories = List<String>.from(
            cachedCategories.split(',')); // Load categories from cache
      });
    } else {
      // If no cached categories, fetch from the server
      await _fetchCategories();
    }
  }

  Future<void> _fetchCategories() async {
    String url = 'https://www.blogger.com/feeds/$blogID/posts/default';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        // Get the list of categories
        _categories = document
            .findAllElements('category')
            .map((category) => category.getAttribute('term'))
            .where((term) => term != null)
            .map((term) => term!)
            .toList();

        // Cache the categories
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'cachedCategories', _categories.join(',')); // Save to cache
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchBlogPosts({String? category, String? searchQuery}) async {
    setState(() {
      _isLoading = true;
    });

    // Build URL
    String url = 'https://www.blogger.com/feeds/$blogID/posts/default';

    if (category != null && category != 'Tất cả bài viết') {
      url += '/-/${Uri.encodeComponent(category)}';
      _selectedCategory = category; // Store the selected category
    }

    url +=
        '?max-results=$_postsPerPage&start-index=${(_currentPage - 1) * _postsPerPage + 1}';
    if (searchQuery != null && searchQuery.isNotEmpty) {
      url +=
          '&q=${Uri.encodeComponent(searchQuery)}'; // Add search query if provided
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final entries = document.findAllElements('entry');

        setState(() async {
          _posts = entries.toList();
          _totalPosts = int.parse(
              document.findAllElements('openSearch:totalResults').first.text);
          _filteredPosts = _posts;
          _totalPages = (_totalPosts / _postsPerPage).ceil();

          // Debugging: Print the number of posts and their titles
          print('Total Posts: $_totalPosts');
          for (var entry in entries) {
            final title = entry.findElements('title').single.text;
            print('Post Title: $title');
          }

          // Cache the data
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'cachedBlogPosts', response.body); // Save to cache

          _isLoading = false;
        });
      } else {
        throw Exception('Không tải được bài viết trên blog');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching blog posts: $e');
    }
  }

  Future<void> refreshData() async {
    await _fetchBlogPosts(); // Fetch data again
  }

  void _nextPage() {
    if ((_currentPage * _postsPerPage) < _totalPosts) {
      setState(() {
        _currentPage++;
        _isLoading = true;
      });
      _fetchBlogPosts(
          category: _selectedCategory); // Pass the selected category
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _isLoading = true;
      });
      _fetchBlogPosts(
          category: _selectedCategory); // Pass the selected category
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bài viết'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BlogSearchDelegate(
                  searchController: _searchController,
                  onSearch: (query) {
                    _fetchBlogPosts(
                        searchQuery:
                            query); // Call the function with the search query
                  },
                ),
              );
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
                'Chuyên Mục',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ..._categories.map((category) {
              return ListTile(
                title: Text(category),
                onTap: () {
                  setState(() {
                    _currentPage =
                        1; // Reset to the first page when a new category is selected
                    _fetchBlogPosts(category: category);
                  });
                  Navigator.pop(context); // Close the drawer
                },
              );
            }).toList(),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshData, // Call refreshData when pulled down
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        ..._filteredPosts.map((post) {
                          final title = post.findElements('title').first.text;
                          final selfLink = post
                              .findElements('link')
                              .firstWhere(
                                (link) => link.getAttribute('rel') == 'self',
                                orElse: () => XmlElement(XmlName('link')),
                              )
                              .getAttribute('href');
                          final published =
                              post.findElements('published').first.text;
                          final thumbnail = _getThumbnail(post);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BlogDetailScreen(postUrl: selfLink!),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 4,
                              margin: EdgeInsets.all(8),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    if (thumbnail != null)
                                      Image.network(
                                        thumbnail,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            published,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        // Pagination controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left),
                              onPressed: _prevPage,
                            ),
                            Text('Page $_currentPage of $_totalPages'),
                            IconButton(
                              icon: Icon(Icons.chevron_right),
                              onPressed: _nextPage,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getThumbnail(XmlElement post) {
    final mediaThumbnails = post.findElements('media:thumbnail');
    if (mediaThumbnails.isNotEmpty) {
      return mediaThumbnails.first.getAttribute('url');
    }

    final content = post.findElements('content').first.text;
    final regExp = RegExp(r'<img.*?src="(.*?)"', caseSensitive: false);
    final match = regExp.firstMatch(content);

    if (match != null) {
      return match.group(1);
    }

    return _defaultImage; // Return default image if no thumbnail is found
  }
}

class BlogSearchDelegate extends SearchDelegate<String> {
  final TextEditingController searchController;
  final Function(String) onSearch;

  BlogSearchDelegate({required this.searchController, required this.onSearch});

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = [
      'Flutter',
      'Dart',
      'Mobile Development',
      'State Management',
      'APIs',
      // Thêm nhiều từ khóa gợi ý khác nếu cần
    ];

    final filteredSuggestions = suggestions
        .where((suggestion) =>
            suggestion.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView(
      children: filteredSuggestions.map((suggestion) {
        return ListTile(
          title: Text(suggestion),
          onTap: () {
            searchController.text =
                suggestion; // Đặt từ khóa đã chọn vào controller
            onSearch(suggestion); // Gọi hàm tìm kiếm với từ khóa đã chọn
            close(context, suggestion); // Đóng hộp thoại tìm kiếm
          },
        );
      }).toList(),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Gọi hàm tìm kiếm với từ khóa đã nhập và đóng hộp thoại tìm kiếm
    onSearch(query);
    close(context, query); // Đóng hộp thoại tìm kiếm
    return Container(); // Không cần trả về gì ở đây
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          searchController.clear(); // Xóa nội dung ô nhập
        },
      ),
      IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          onSearch(query); // Thực hiện tìm kiếm khi nhấn nút
          close(context, query); // Đóng hộp thoại tìm kiếm
        },
      ),
    ];
  }
}
