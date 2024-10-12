import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'blogDetailScreen.dart';
import 'package:hpc_students/include/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
// Thêm import này cho rootBundle

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
  String? _selectedCategory; // Biến để lưu trữ danh mục đã chọn
  String _defaultImage =
      'https://blogger.googleusercontent.com/img/a/AVvXsEiYorgTwvKTp7bjT_1O6HrAl2K4vYEcimlyzfv-0UNwF8x_ov7avCHuZoVdg6K-u2GhL7bOUOmL9DSC4YiBQOF82bmOxYFhmzcd_S15-AikwfL83vmYIAPuBtCPGeRsRfAiVw0REdGk-GZltwNDSWuKC-WFGvU1WwUCASD8CynnsGpOH91geRjUW2rVmC0=w220-h146-p-k-no-nu'; // Đường dẫn hình ảnh mặc định

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentSearchQuery = ''; // Biến để lưu trữ truy vấn tìm kiếm hiện tại

  @override
  void initState() {
    super.initState();
    _loadData(); // Tải dữ liệu khi khởi tạo
    _loadSearchQuery(); // Tải truy vấn tìm kiếm từ SharedPreferences
  }

  Future<void> _loadSearchQuery() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedQuery =
        prefs.getString('currentSearchQuery'); // Tải truy vấn tìm kiếm đã lưu
    if (savedQuery != null) {
      setState(() {
        _currentSearchQuery = savedQuery; // Đặt truy vấn tìm kiếm hiện tại
      });
      _fetchBlogPosts(
          searchQuery: savedQuery); // Lấy bài viết dựa trên truy vấn đã lưu
    }
  }

  Future<void> _loadData() async {
    print(
        'Đang tải dữ liệu...'); // Ghi chú: Chỉ ra rằng việc tải dữ liệu đã bắt đầu
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData =
          prefs.getString('cachedBlogPosts'); // Tải dữ liệu đã lưu
      String? cachedCategories =
          prefs.getString('cachedCategories'); // Tải danh mục đã lưu

      if (cachedData != null) {
        print(
            'Đã tìm thấy dữ liệu đã lưu.'); // Ghi chú: Chỉ ra rằng dữ liệu đã lưu được tìm thấy
        try {
          print(
              'Dữ liệu đã lưu: $cachedData'); // In ra dữ liệu đã lưu để kiểm tra
          final document = XmlDocument.parse(cachedData); // Phân tích XML
          final entries = document.findAllElements('entry');
          setState(() {
            _posts = entries.toList();
            _totalPosts = int.parse(
                document.findAllElements('openSearch:totalResults').first.text);
            _filteredPosts = _posts;
            _totalPages = (_totalPosts / _postsPerPage).ceil();
            _isLoading =
                false; // Đảm bảo trạng thái loading được đặt thành false sau khi tải dữ liệu đã lưu
            print(
                'Dữ liệu đã được tải thành công. Tổng số bài viết: $_totalPosts'); // Ghi chú: Chỉ ra việc tải dữ liệu thành công
          });
        } catch (e) {
          print('Lỗi khi phân tích dữ liệu đã lưu: $e'); // Ghi lại lỗi
          _isLoading = false; // Đảm bảo trạng thái loading được đặt thành false
          await _fetchBlogPosts(); // Tùy chọn, lấy dữ liệu mới nếu dữ liệu đã lưu không hợp lệ
        }
      } else {
        print(
            'Không tìm thấy dữ liệu đã lưu. Đang lấy từ máy chủ...'); // Ghi chú: Chỉ ra rằng không có dữ liệu đã lưu
        await _fetchBlogPosts(); // Nếu không có dữ liệu đã lưu, lấy từ máy chủ
      }

      if (cachedCategories != null) {
        print(
            'Đã tìm thấy danh mục đã lưu.'); // Ghi chú: Chỉ ra rằng danh mục đã lưu được tìm thấy
        setState(() {
          _categories = List<String>.from(
              cachedCategories.split(',')); // Tải danh mục từ bộ nhớ cache
        });
      } else {
        print(
            'Không tìm thấy danh mục đã lưu. Đang lấy từ máy chủ...'); // Ghi chú: Chỉ ra rằng không có danh mục đã lưu
        await _fetchCategories();
        print('Đã tải danh mục!');
      }
    } catch (e) {
      print(
          'Lỗi khi tải dữ liệu: $e'); // Ghi lại bất kỳ lỗi nào xảy ra trong quá trình tải
      setState(() {
        _isLoading =
            false; // Đảm bảo trạng thái loading được đặt thành false khi có lỗi
      });
    }
  }

  Future<void> _fetchCategories() async {
    String url = 'https://www.blogger.com/feeds/$blogID/posts/default';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        // Lấy danh sách các danh mục
        _categories = document
            .findAllElements('category')
            .where((category) =>
                category.getAttribute('term') != null &&
                category.getAttribute('scheme') ==
                    null) // Lọc chỉ các chuyên mục không có scheme
            .map((category) => category.getAttribute('term')!)
            .toList();

        // Lưu danh mục vào bộ nhớ cache
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'cachedCategories', _categories.join(',')); // Lưu vào bộ nhớ cache

        // Cập nhật lại trạng thái để hiển thị danh mục
        setState(() {});
      }
    } catch (e) {
      print('Lỗi khi lấy danh mục: $e');
    }
  }

  Future<void> _fetchBlogPosts({String? category, String? searchQuery}) async {
    setState(() {
      _isLoading = true; // Đặt trạng thái loading
    });

    // Xây dựng URL
    String url = 'https://www.blogger.com/feeds/$blogID/posts/default';

    if (category != null && category != 'Tất cả bài viết') {
      url += '/-/${Uri.encodeComponent(category)}';
      _selectedCategory = category; // Lưu trữ danh mục đã chọn
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      url +=
          '?q=${Uri.encodeComponent(searchQuery)}&max-results=$_postsPerPage'; // Cập nhật URL cho tìm kiếm
    } else {
      url +=
          '?max-results=$_postsPerPage&start-index=${(_currentPage - 1) * _postsPerPage + 1}';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final entries = document.findAllElements('entry');

        // Di chuyển cuộc gọi setState ra ngoài hoạt động async
        setState(() {
          _posts = entries.toList();
          _totalPosts = int.parse(
              document.findAllElements('openSearch:totalResults').first.text);
          _filteredPosts = _posts;
          _totalPages = (_totalPosts / _postsPerPage).ceil();
        });

        // Ghi chú: In ra số lượng bài viết và tiêu đề của chúng
        print('Tổng số bài viết: $_totalPosts');
        for (var entry in entries) {
          final title = entry.findElements('title').single.text;
        }

        // Lưu dữ liệu vào bộ nhớ cache
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'cachedBlogPosts', response.body); // Lưu vào bộ nhớ cache
        await prefs.setString('currentSearchQuery',
            searchQuery ?? ''); // Lưu truy vấn tìm kiếm hiện tại

        // Đặt trạng thái loading thành false sau khi dữ liệu được lấy
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Không tải được bài viết trên blog');
      }
    } catch (e) {
      setState(() {
        _isLoading =
            false; // Đảm bảo trạng thái loading được đặt thành false khi có lỗi
      });
      print('Lỗi khi lấy bài viết: $e');
    }
  }

  Future<void> refreshData() async {
    await _fetchBlogPosts(); // Lấy dữ liệu lại
  }

  void _nextPage() {
    if ((_currentPage * _postsPerPage) < _totalPosts) {
      setState(() {
        _currentPage++;
        _isLoading = true;
      });
      _fetchBlogPosts(category: _selectedCategory); // Truyền danh mục đã chọn
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _isLoading = true;
      });
      _fetchBlogPosts(category: _selectedCategory); // Truyền danh mục đã chọn
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_currentSearchQuery.isNotEmpty
            ? 'Tìm kiếm: $_currentSearchQuery' // Hiển thị truy vấn tìm kiếm nếu có
            : 'Bài viết'), // Tiêu đề mặc định
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BlogSearchDelegate(
                  searchController: _searchController,
                  onSearch: (query) {
                    setState(() {
                      _currentSearchQuery =
                          query; // Cập nhật truy vấn tìm kiếm hiện tại
                    });
                    _fetchBlogPosts(
                        searchQuery: query); // Gọi hàm với truy vấn tìm kiếm
                  },
                  categories: _categories, // Truyền danh mục cho delegate
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState
                  ?.openEndDrawer(); // Sử dụng key để mở drawer
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Container(
                child: Text(
                  'Chuyên Mục',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              decoration: BoxDecoration(
                color: Color(0xFF2d59a4),
              ),
            ),
            ListTile(
              title: Text('Tất cả bài viết'), // Mục Tất cả bài viết
              onTap: () {
                setState(() {
                  _currentSearchQuery = ''; // Xóa truy vấn tìm kiếm
                  _selectedCategory = null; // Xóa danh mục đã chọn
                  _currentPage = 1; // Đặt lại về trang đầu tiên
                });
                _fetchBlogPosts(); // Lấy tất cả bài viết
                Navigator.pop(context); // Đóng drawer
              },
            ),
            ..._categories.map((category) {
              return ListTile(
                title: Text(category),
                onTap: () {
                  setState(() {
                    _currentPage =
                        1; // Đặt lại về trang đầu tiên khi chọn danh mục mới
                    _selectedCategory = category; // Đặt danh mục đã chọn
                    _currentSearchQuery = ''; // Xóa truy vấn tìm kiếm
                  });
                  _fetchBlogPosts(
                      category: category); // Lấy bài viết cho danh mục đã chọn
                  Navigator.pop(context); // Đóng drawer
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
              onRefresh: refreshData, // Gọi refreshData khi kéo xuống
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _posts.isEmpty // Kiểm tra xem có bài viết nào không
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/Blog/noPosts.svg',
                                width: MediaQuery.of(context).size.width,
                                height: null,
                                fit: BoxFit.cover,
                              ),
                              Text(
                                'Không có bài viết nào.',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          children: [
                            ..._filteredPosts.map((post) {
                              final title =
                                  post.findElements('title').first.text;
                              final selfLink = post
                                  .findElements('link')
                                  .firstWhere(
                                    (link) =>
                                        link.getAttribute('rel') == 'self',
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
                            // Điều khiển phân trang
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.chevron_left),
                                  onPressed: _prevPage,
                                ),
                                Text('Trang $_currentPage tổng $_totalPages'),
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

    return _defaultImage; // Trả về hình ảnh mặc định nếu không tìm thấy thumbnail
  }
}

class BlogSearchDelegate extends SearchDelegate<String> {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final List<String> categories; // Thêm tham số cho danh mục

  BlogSearchDelegate({
    required this.searchController,
    required this.onSearch,
    required this.categories, // Khởi tạo danh mục
  });

  @override
  String get searchFieldLabel => 'Tìm kiếm...'; // Thay đổi nhãn ô tìm kiếm

  @override
  Widget buildSuggestions(BuildContext context) {
    // Kiểm tra xem có danh mục nào không
    if (categories.isEmpty) {
      return Container(); // Trả về container rỗng nếu không có danh mục
    }

    // Ngẫu nhiên chọn tối đa 5 danh mục, cho phép lặp lại
    final List<String> randomSuggestions = [];
    final random = Random();

    for (int i = 0; i < 5; i++) {
      randomSuggestions.add(categories[random.nextInt(categories.length)]);
    }

    final filteredSuggestions = randomSuggestions
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
            // Gọi hàm tìm kiếm với từ khóa đã chọn sau khi đóng hộp thoại
            Future.microtask(() => onSearch(suggestion));
            close(context, suggestion); // Đóng hộp thoại tìm kiếm
          },
        );
      }).toList(),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Gọi hàm tìm kiếm với từ khóa đã nhập và đóng hộp thoại tìm kiếm
    Future.microtask(() => onSearch(query)); // Gọi hàm tìm kiếm với truy vấn
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
          Future.microtask(
              () => onSearch(query)); // Thực hiện tìm kiếm khi nhấn nút
          close(context, query); // Đóng hộp thoại tìm kiếm
        },
      ),
    ];
  }
}
