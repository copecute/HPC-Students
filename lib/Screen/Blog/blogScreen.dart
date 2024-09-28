import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'blogDetailScreen.dart';

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
  String? _selectedCategory; // Biến để lưu chuyên mục đã chọn

  @override
  void initState() {
    super.initState();
    _fetchBlogPosts(); // Lấy bài viết mặc định
  }

  Future<void> _fetchBlogPosts({String? category, String? searchQuery}) async {
    setState(() {
      _isLoading = true;
    });

    // Xây dựng URL
    String url = 'https://www.blogger.com/feeds/1068271185371072211/posts/default';

    if (category != null) {
      url += '/-/${Uri.encodeComponent(category)}'; // Thay thế 'tên chuyên mục' bằng tên category
      _selectedCategory = category; // Lưu chuyên mục đã chọn
    }

    url += '?max-results=$_postsPerPage&start-index=${(_currentPage - 1) * _postsPerPage + 1}';
    if (searchQuery != null && searchQuery.isNotEmpty) {
      url += '&q=${Uri.encodeComponent(searchQuery)}'; // Thêm từ khóa tìm kiếm nếu có
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final entries = document.findAllElements('entry');

        setState(() {
          _posts = entries.toList();
          _totalPosts =
              int.parse(document.findAllElements('openSearch:totalResults').first.text);
          _filteredPosts = _posts;
          _totalPages = (_totalPosts / _postsPerPage).ceil();

          // Lấy danh sách chuyên mục
          _categories = document.findAllElements('category')
              .map((category) => category.getAttribute('term'))
              .where((term) => term != null)
              .map((term) => term!)
              .toList();

          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load blog posts');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchPosts(String query) {
    _fetchBlogPosts(searchQuery: query); // Gọi lại hàm với từ khóa tìm kiếm
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

    return 'https://blogger.googleusercontent.com/img/a/AVvXsEiYorgTwvKTp7bjT_1O6HrAl2K4vYEcimlyzfv-0UNwF8x_ov7avCHuZoVdg6K-u2GhL7bOUOmL9DSC4YiBQOF82bmOxYFhmzcd_S15-AikwfL83vmYIAPuBtCPGeRsRfAiVw0REdGk-GZltwNDSWuKC-WFGvU1WwUCASD8CynnsGpOH91geRjUW2rVmC0=w220-h146-p-k-no-nu';
  }

  void _nextPage() {
    if ((_currentPage * _postsPerPage) < _totalPosts) {
      setState(() {
        _currentPage++;
        _isLoading = true;
      });
      _fetchBlogPosts(category: _selectedCategory); // Truyền chuyên mục đã chọn
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _isLoading = true;
      });
      _fetchBlogPosts(category: _selectedCategory); // Truyền chuyên mục đã chọn
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
        _isLoading = true;
      });
      _fetchBlogPosts(category: _selectedCategory); // Truyền chuyên mục đã chọn
    }
  }

  List<Widget> _buildPageButtons() {
    List<Widget> pageButtons = [];

    pageButtons.add(IconButton(
      icon: Icon(Icons.chevron_left),
      onPressed: _prevPage,
    ));

    if (_currentPage > 1) {
      pageButtons.add(
        TextButton(
          onPressed: () => _goToPage(1),
          child: Text('1'),
        ),
      );
    }

    if (_totalPages > 4) {
      if (_currentPage > 3) {
        pageButtons.add(Text('...'));
      }

      int start = _currentPage > 2 ? _currentPage - 1 : 2;
      int end = _currentPage < _totalPages - 1 ? _currentPage + 1 : _totalPages - 1;

      for (int i = start; i <= end; i++) {
        if (i >= 2 && i < _totalPages) {
          pageButtons.add(
            TextButton(
              onPressed: () => _goToPage(i),
              child: Text(
                '$i',
                style: TextStyle(
                  fontWeight: i == _currentPage ? FontWeight.bold : FontWeight.normal,
                  color: i == _currentPage ? Colors.blue : Colors.black,
                ),
              ),
            ),
          );
        }
      }

      if (_currentPage < (_totalPages - 2)) {
        pageButtons.add(Text('...'));
      }
    }

    if (_totalPages > 1) {
      pageButtons.add(
        TextButton(
          onPressed: () => _goToPage(_totalPages),
          child: Text('$_totalPages'),
        ),
      );
    }

    pageButtons.add(IconButton(
      icon: Icon(Icons.chevron_right),
      onPressed: _nextPage,
    ));

    return pageButtons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blog'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BlogSearchDelegate(
                  searchController: _searchController,
                  onSearch: _searchPosts,
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
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
                    _currentPage = 1; // Đặt lại trang về 1 khi chọn chuyên mục mới
                    _fetchBlogPosts(category: category);
                  });
                  Navigator.pop(context); // Đóng Navigation Drawer
                },
              );
            }).toList(),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          ..._filteredPosts.map((post) {
            final title = post.findElements('title').first.text;
            final selfLink = post.findElements('link').firstWhere(
                  (link) => link.getAttribute('rel') == 'self',
              orElse: () => XmlElement(XmlName('link')),
            ).getAttribute('href');
            final published = post.findElements('published').first.text;
            final thumbnail = _getThumbnail(post);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlogDetailScreen(postUrl: selfLink!),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
          if (_totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildPageButtons(),
            ),
        ],
      ),
    );
  }
}

class BlogSearchDelegate extends SearchDelegate<String> {
  final TextEditingController searchController;
  final Function(String) onSearch;

  BlogSearchDelegate({required this.searchController, required this.onSearch});

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text('Search for: ${query.isNotEmpty ? query : '...' }'),
        ),
      ],
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
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
    // TODO: implement buildActions
    throw UnimplementedError();
  }
}
