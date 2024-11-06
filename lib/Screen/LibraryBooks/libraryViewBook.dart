import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hpc_students/include/config.dart';
import 'package:provider/provider.dart';
import 'package:hpc_students/Screen/LibraryBooks/library_cart_provider.dart';
import 'package:hpc_students/Screen/LibraryBooks/library_cart_screen.dart';

class LibraryViewBook extends StatefulWidget {
  final Map<String, dynamic> bookData;

  LibraryViewBook({required this.bookData});

  @override
  _LibraryViewBookState createState() => _LibraryViewBookState();
}

class _LibraryViewBookState extends State<LibraryViewBook> {
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic> bookDetail = {};

  @override
  void initState() {
    super.initState();
    print("Initializing LibraryViewBook...");
    _fetchBookDetail();
  }

  Future<void> _fetchBookDetail() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
      });

      print("Fetching book detail for STT: ${widget.bookData['STT']}");

      final url = SpreadsheetAPI.libraryBooks;

      print('Fetching book detail from URL: $url');
      print('Request body: ${{
        'copecute': SpreadApiKey,
        'action': 'getBook',
        'stt': widget.bookData['STT'].toString()
      }}');

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': SpreadApiKey,
          'action': 'getBook',
          'stt': widget.bookData['STT'].toString(),
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      print("Response status: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response data: $data");

        setState(() {
          bookDetail = data;
          isLoading = false;
          errorMessage = '';
        });
      } else if (response.statusCode == 302) {
        print("Redirected to: ${response.headers['location']}");
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (!mounted) return;

          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            print("Response data after redirect: $data");

            setState(() {
              bookDetail = data;
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
      print("Error fetching book detail: $e");
      if (!mounted) return;

      setState(() {
        errorMessage = 'Có lỗi xảy ra khi tải thông tin sách.';
        isLoading = false;
      });
    }
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
          'Chi tiết sách',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle:
            isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        actions: [
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                bookDetail['IMG'] ?? widget.bookData['IMG'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, size: 100),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookDetail['NAME']?.toString() ??
                        widget.bookData['NAME'] ??
                        '',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bookDetail['Category']?['NAME'] ??
                          widget.bookData['Category']?['NAME'] ??
                          'Chưa phân loại',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Mô tả',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  isLoading
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Text(
                          bookDetail['Description'] ??
                              widget.bookData['Description'] ??
                              '',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            context
                .read<LibraryCartProvider>()
                .addItem(bookDetail.isNotEmpty ? bookDetail : widget.bookData);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã thêm vào giỏ sách')),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: Text(
            'Thêm vào giỏ sách',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
