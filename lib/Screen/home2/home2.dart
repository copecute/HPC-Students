import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:convert';
import 'package:hpc_students/Screen/menu/menuScreen.dart';
import 'package:hpc_students/Screen/rankScreen.dart';
import 'package:hpc_students/Screen/timNguoiYeu/chat.dart';
import 'package:hpc_students/Screen/traDiemScreen.dart';
import 'package:xml/xml.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hpc_students/Screen/Blog/blogDetailScreen.dart';
import 'package:hpc_students/Screen/Blog/blogScreen.dart';
import 'package:hpc_students/Screen/home/blog_service.dart';
import 'package:hpc_students/Screen/home/data_service.dart';
import 'package:hpc_students/Screen/home/firebase_service.dart';

import 'package:hpc_students/Screen/home/schedule_card.dart';
import 'package:hpc_students/include/config.dart';
import 'package:hpc_students/include/cookie_provider.dart';
import 'package:hpc_students/Screen/loginScreen.dart';
import 'package:hpc_students/Screen/home2/action.dart';
import 'package:hpc_students/Screen/home2/icon_img_button.dart';
import 'package:hpc_students/Screen/home2/notification_handler.dart';
import 'package:hpc_students/include/theme_provider.dart';

class HomeScreen2 extends StatelessWidget {
  const HomeScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'HPC Students',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2d59a4),
              primary: const Color(0xFF2d59a4),
            ),
          ),
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late double minExtent;
  late double maxExtent;
  final ScrollController scrollController = ScrollController();

  String _hoTen = 'N/A';
  String _trangThai = 'N/A';
  String _maSinhVien = 'N/A';
  String _tinChiTichLuy = '0';
  String _tbcTichLuy = '0';
  String _xepLoaiHT = 'N/A';
  bool _isLoading = true;
  List<Map<String, String>> _blogPosts = [];
  double _tbcTichLuyValue = 0.0;
  double _maxTbcValue = 10.0;
  String _defaultImage =
      'https://blogger.googleusercontent.com/img/a/AVvXsEiYorgTwvKTp7bjT_1O6HrAl2K4vYEcimlyzfv-0UNwF8x_ov7avCHuZoVdg6K-u2GhL7bOUOmL9DSC4YiBQOF82bmOxYFhmzcd_S15-AikwfL83vmYIAPuBtCPGeRsRfAiVw0REdGk-GZltwNDSWuKC-WFGvU1WwUCASD8CynnsGpOH91geRjUW2rVmC0=w220-h146-p-k-no-nu';
  List<Map<String, String>> _cachedBlogPosts = [];
  bool _hasFetchedData = false;
  late BlogService blogService;
  late DataService dataService;
  late FirebaseService firebaseService;

  @override
  void initState() {
    super.initState();
    dataService = DataService();
    firebaseService = FirebaseService();
    blogService = BlogService(blogID);
    _loadCachedData();
    _loadCachedBlogPosts();
  }

  Future<void> _loadCachedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hoTen = prefs.getString('hoTen') ?? 'N/A';
      _trangThai = prefs.getString('trangThai') ?? 'N/A';
      _maSinhVien = prefs.getString('maSinhVien') ?? 'N/A';
      _tinChiTichLuy = prefs.getString('tinChiTichLuy') ?? '0';
      _tbcTichLuy = prefs.getString('tbcTichLuy') ?? '0';
      _xepLoaiHT = prefs.getString('xepLoaiHT') ?? 'N/A';
      _isLoading = _hoTen.isEmpty;
      _tbcTichLuyValue = double.tryParse(_tbcTichLuy) ?? 0.0;
    });

    if (_hoTen.isEmpty) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    String? cookie =
        Provider.of<CookieProvider>(context, listen: false).getCookie();

    if (cookie == null || cookie.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      return;
    }

    dataService.fetchData(cookie, (data) {
      setState(() {
        _maSinhVien = data['maSinhVien']!;
        _hoTen = data['hoTen']!;
        _trangThai = data['trangThai']!;
        _tinChiTichLuy = data['tinChiTichLuy']!;
        _tbcTichLuy = data['tbcTichLuy']!;
        _xepLoaiHT = data['xepLoaiHT']!;
        _isLoading = false;
        _saveOrUpdateToFirestore();
        _cacheData();
      });
    }, (error) {
      _showSnackBar(error);
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _loadCachedBlogPosts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedPosts = prefs.getString('cachedBlogPosts');
    if (cachedPosts != null) {
      setState(() {
        if (cachedPosts.trim().startsWith('<')) {
          _blogPosts = _parseXmlData(cachedPosts);
        } else {
          _blogPosts = List<Map<String, String>>.from(json
              .decode(cachedPosts)
              .map((post) => Map<String, String>.from(post)));
        }
        _hasFetchedData = true;
      });
    } else {
      _fetchBlogPosts();
    }
  }

  Future<void> _fetchBlogPosts() async {
    await blogService.loadBlogPosts();
    setState(() {
      _blogPosts = blogService.blogPosts;
    });
  }

  Future<void> _cacheData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('hoTen', _hoTen);
    await prefs.setString('trangThai', _trangThai);
    await prefs.setString('maSinhVien', _maSinhVien);
    await prefs.setString('tinChiTichLuy', _tinChiTichLuy);
    await prefs.setString('tbcTichLuy', _tbcTichLuy);
    await prefs.setString('xepLoaiHT', _xepLoaiHT);
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchData();
    await _fetchBlogPosts();
  }

  Future<void> _saveOrUpdateToFirestore() async {
    await dataService.saveOrUpdateToFirestore(
        _maSinhVien, _hoTen, _trangThai, _tbcTichLuy);
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  List<Map<String, String>> _parseXmlData(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    List<Map<String, String>> posts = [];
    final entries = document.findAllElements('entry');

    for (var entry in entries) {
      final title = entry.findElements('title').single.text;
      final published = entry.findElements('published').single.text;
      final category = entry
          .findElements('category')
          .firstWhere(
            (link) =>
                link.getAttribute('scheme') ==
                'http://www.blogger.com/atom/ns#',
            orElse: () => XmlElement(XmlName('category')),
          )
          .getAttribute('term');

      final selfLink = entry
          .findElements('link')
          .firstWhere(
            (link) => link.getAttribute('rel') == 'self',
            orElse: () => XmlElement(XmlName('link')),
          )
          .getAttribute('href');

      final imageUrl = _getThumbnail(entry);

      if (selfLink != null) {
        posts.add({
          'title': title,
          'published': published,
          'category': category ?? "Mới",
          'self': selfLink,
          'image': imageUrl ?? _defaultImage,
        });
      }
    }
    return posts;
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
    return _defaultImage;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    minExtent = kToolbarHeight + MediaQuery.paddingOf(context).top;
    maxExtent = Platform.isAndroid ? 216 : 256;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: AppBarScrollHandler(
          minExtent: minExtent,
          maxExtent: maxExtent,
          controller: scrollController,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverAppBarDelegate(
                  minExtent: minExtent,
                  maxExtent: maxExtent,
                  maSinhVien: _maSinhVien,
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      child: Card(
                        margin: EdgeInsets.all(0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              SizedBox(height: 5),
                              Text(
                                'TBC tích lũy $_tbcTichLuy, Xếp loại $_xepLoaiHT',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Tín chỉ tích lũy $_tinChiTichLuy',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ScheduleCard(),
                    SizedBox(height: 2000),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tin tức',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlogScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Xem tất cả >',
                          style: TextStyle(
                            color: Color(0xFF2d59a4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _blogPosts.isEmpty && !_isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Container(
                        height: 150, // Chiều cao cố định cho phần tin tức
                        child: _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _blogPosts.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width:
                                        350, // Chiều rộng cố định cho mỗi Card
                                    margin: EdgeInsets.symmetric(horizontal: 8),
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BlogDetailScreen(
                                                postUrl: _blogPosts[index]
                                                    ['self']!,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                child: Image.network(
                                                  _blogPosts[index]['image'] ??
                                                      '',
                                                  width: 120,
                                                  height: 120,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _blogPosts[index]
                                                                      ['title']!
                                                                  .length >
                                                              50
                                                          ? _blogPosts[index]
                                                                      ['title']!
                                                                  .substring(
                                                                      0, 50) +
                                                              '...'
                                                          : _blogPosts[index]
                                                              ['title']!,
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      _blogPosts[index][
                                                                      'category']!
                                                                  .length >
                                                              50
                                                          ? _blogPosts[index][
                                                                      'category']!
                                                                  .substring(
                                                                      0, 50) +
                                                              '...'
                                                          : _blogPosts[index]
                                                              ['category']!,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  const SliverAppBarDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.maSinhVien,
  });

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final String maSinhVien;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent;
  }

  @override
  OverScrollHeaderStretchConfiguration? get stretchConfiguration =>
      OverScrollHeaderStretchConfiguration();

  double get deltaExtent => maxExtent - minExtent;

  static const imgBgr = Image(
      image: AssetImage('assets/images/header_bg.jpg'), fit: BoxFit.cover);

  double transform(double begin, double end, double t, [double x = 1]) {
    return Tween<double>(begin: begin, end: end)
        .transform(x == 1 ? t : min(1.0, t * x));
  }

  Color transformColor(Color? begin, Color? end, double t, [double x = 1]) {
    return ColorTween(begin: begin, end: end)
            .transform(x == 1 ? t : min(1.0, t * x)) ??
        Colors.transparent;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Lấy provider của theme để kiểm tra xem đang ở chế độ sáng hay tối
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    // Tính toán độ cao hiện tại của thanh ứng dụng dựa trên độ cao tối thiểu, tối đa và độ lệch thu nhỏ
    final currentExtent = max(minExtent, maxExtent - shrinkOffset);
    // Tính toán giá trị t để xác định mức độ thu nhỏ của thanh ứng dụng
    // 0.0 -> Mở rộng
    // 1.0 -> Thu nhỏ
    double t =
        clampDouble(1.0 - (currentExtent - minExtent) / deltaExtent, 0, 1);
    // Gửi thông báo về mức độ thu nhỏ của thanh ứng dụng
    CollapsingNotification(t).dispatch(context);

    // Tạo một hộp có màu sắc thay đổi dựa trên mức độ thu nhỏ của thanh ứng dụng
    final splashColoredBox = ColoredBox(
        color: transformColor(
            null, isDarkMode ? Colors.black : Colors.white, t, 3));

    // Trả về một chồng các widget để xây dựng giao diện
    return Stack(
      clipBehavior: Clip.none,
      children: [
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final List<Widget> children = <Widget>[];

            double imgBgrHeight = maxExtent;

            // Background image
            if (constraints.maxHeight > imgBgrHeight)
              imgBgrHeight = constraints.maxHeight;
            children
              ..add(Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: imgBgrHeight - deltaExtent / 2,
                child: imgBgr,
              ))

              // Splash transform color bottom
              ..add(Positioned(
                bottom: 0,
                width: constraints.maxWidth,
                height: deltaExtent,
                child: splashColoredBox,
              ));

            // Card
            const double cardPadding = 8;
            const double cardMarginHorizontal = 16;
            children
              ..add(
                Positioned(
                  left: cardMarginHorizontal,
                  right: cardMarginHorizontal,
                  bottom: 0,
                  height: deltaExtent,
                  child: ActionAndOverviewInfoCard(
                    contentPadding: const EdgeInsets.all(cardPadding),
                    borderRadius: BorderRadius.circular(transform(12, 0, t, 2)),
                  ),
                ),
              )

              // Background image Clipped
              ..add(Positioned(
                top: 0,
                height: imgBgrHeight - deltaExtent / 2,
                width: constraints.maxWidth,
                child: ClipRect(
                  clipper: RectClipper(minExtent),
                  child: imgBgr,
                ),
              ))

              // Splash transform color top
              ..add(Positioned(
                top: 0,
                height: minExtent,
                width: constraints.maxWidth,
                child: splashColoredBox,
              ));
            // App bar
            const appBarPadding = SizedBox(
                width:
                    10); // Kích thước của khoảng cách lề trái và phải của app bar
            final appBarContentWidth = constraints.maxWidth -
                (appBarPadding.width! *
                    2); // Tính toán chiều rộng của nội dung app bar
            const totalIconImgButtonSize = IconImgButton.tapTargetSize *
                7; // Tổng kích thước của các nút icon
            final appBarSpace = SizedBox(
                width: (appBarContentWidth - totalIconImgButtonSize) /
                    6); // Tính toán khoảng cách giữa các nút icon

            //App bar fixed position
            Color iconBgrColor = transformColor(Colors.black54, null, t, 4);
            children.add(Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: Container(
                height: minExtent,
                color: transformColor(null, const Color(0xFF2d59a4), t, 2),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      appBarPadding,
                      SearchArea(
                        appBarContentWidth: appBarContentWidth,
                        appBarSpace: appBarSpace,
                        iconBgrColor: iconBgrColor,
                      ),
                      appBarSpace,
                      const Spacer(),
                      appBarSpace,
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return PopupMenuButton<ThemeMode>(
                            icon: Icon(
                              themeProvider.themeMode == ThemeMode.dark
                                  ? Icons.wb_sunny // Sun icon for light theme
                                  : Icons
                                      .nights_stay, // Moon icon for dark theme
                              color: Colors.white,
                            ),
                            onSelected: (ThemeMode newValue) {
                              themeProvider.toggleTheme(newValue);
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem(
                                value: ThemeMode.light,
                                child: Text('Sáng'),
                              ),
                              PopupMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Tối'),
                              ),
                              PopupMenuItem(
                                value: ThemeMode.system,
                                child: Text('Hệ thống'),
                              ),
                            ],
                          );
                        },
                      ),
                      appBarPadding,
                    ],
                  ),
                ),
              ),
            ));

            // App bar transform position
            iconBgrColor = transformColor(const Color(0xFF2d59a4), null, t, 2);
            final iconSize = transform(44, 32, t, 2);
            final iconPadding = transform(8, 4, t, 2);
            final double cardWidth =
                constraints.maxWidth - (cardMarginHorizontal * 2);
            final cardSpace =
                (cardWidth - (IconImgButton.tapTargetSize * 4)) / 5;

            children.add(Positioned(
              left: transform(
                cardSpace + cardPadding,
                appBarPadding.width! +
                    IconImgButton.tapTargetSize +
                    appBarSpace.width!,
                t,
                2,
              ),
              right: transform(
                cardSpace + cardPadding,
                appBarPadding.width! +
                    IconImgButton.tapTargetSize * 2 +
                    appBarSpace.width! * 2,
                t,
                2,
              ),
              top: constraints.maxHeight > maxExtent
                  ? null
                  : transform(minExtent + cardPadding,
                      minExtent - IconImgButton.tapTargetSize - 4, t, 2),
              bottom: constraints.maxHeight < maxExtent
                  ? null
                  : deltaExtent - IconImgButton.tapTargetSize - cardPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: iconBgrColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.favorite, color: Colors.white),
                      iconSize: iconSize * 0.6, // Make the icon smaller
                      padding: EdgeInsets.all(
                          iconPadding * 0.8), // Adjust padding accordingly
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(username: maSinhVien)),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: iconBgrColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.stars, color: Colors.white),
                      iconSize: iconSize * 0.6, // Make the icon smaller
                      padding: EdgeInsets.all(
                          iconPadding * 0.8), // Adjust padding accordingly
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RankScreen()),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: iconBgrColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add_chart, color: Colors.white),
                      iconSize: iconSize * 0.6, // Make the icon smaller
                      padding: EdgeInsets.all(
                          iconPadding * 0.8), // Adjust padding accordingly
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TraDiemScreen()),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: iconBgrColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.grid_view, color: Colors.white),
                      iconSize: iconSize * 0.6, // Make the icon smaller
                      padding: EdgeInsets.all(
                          iconPadding * 0.8), // Adjust padding accordingly
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MenuScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ));

            return Stack(children: children);
          },
        ),
      ],
    );
  }
}

// Thêm các class phụ trợ nếu chúng chưa được định nghĩa
class SearchArea extends StatelessWidget {
  const SearchArea({
    super.key,
    required this.appBarContentWidth,
    required this.appBarSpace,
    required this.iconBgrColor,
  });

  final double appBarContentWidth;
  final SizedBox appBarSpace;
  final Color iconBgrColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          width: appBarContentWidth -
              IconImgButton.tapTargetSize * 2 -
              appBarSpace.width! * 3 -
              4,
          height: 32,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: iconBgrColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        IconImgButton(
          'search.webp',
          backgroundColor: Colors.transparent,
          onTap: () {
            print('icon search được ấn!');
          },
        ),
      ],
    );
  }
}

class RectClipper extends CustomClipper<Rect> {
  final double maxHeight;

  RectClipper(this.maxHeight);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, maxHeight);
  }

  @override
  bool shouldReclip(RectClipper oldClipper) =>
      oldClipper.maxHeight != maxHeight;
}
