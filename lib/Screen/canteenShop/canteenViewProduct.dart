import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hpc_students/include/config.dart';
import 'package:provider/provider.dart';
import 'package:hpc_students/Screen/canteenShop/cart_provider.dart';
import 'package:hpc_students/Screen/canteenShop/cartScreen.dart';

class CanteenViewProduct extends StatefulWidget {
  final Map<String, dynamic> productData;

  CanteenViewProduct({required this.productData});

  @override
  _CanteenViewProductState createState() => _CanteenViewProductState();
}

class _CanteenViewProductState extends State<CanteenViewProduct> {
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic> productDetail = {};

  @override
  void initState() {
    super.initState();
    print("Initializing CanteenViewProduct...");
    _fetchProductDetail();
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0 đ';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
  }

  Future<void> _fetchProductDetail() async {
    try {
      setState(() {
        isLoading = true;
      });

      print("Fetching product detail for STT: ${widget.productData['STT']}");

      final url =
          'https://script.google.com/macros/s/AKfycbwLIYesYJgBbpOFWhCPxfpMSxnFrZZSbv9iMorkPyG0b8HkRKv6RLpqlsVrkEk5vGoh/exec';

      print('Fetching product detail from URL: $url');
      print('Request body: ${{
        'copecute': 'MIiwxJTx8h3a3HLYvpYpWXsywFH71f5jYP1IQo8AMUwmZr9H7y',
        'action': 'getProduct',
        'stt': widget.productData['STT'].toString()
      }}');

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': 'MIiwxJTx8h3a3HLYvpYpWXsywFH71f5jYP1IQo8AMUwmZr9H7y',
          'action': 'getProduct',
          'stt': widget.productData['STT'].toString(),
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
          productDetail = data;
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
              productDetail = data;
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
      print("Error fetching product detail: $e");
      setState(() {
        errorMessage = 'Có lỗi xảy ra khi tải thông tin sản phẩm.';
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
          'Chi tiết sản phẩm',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                widget.productData['IMG'] ?? '',
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
                    productDetail['NAME']?.toString() ??
                        widget.productData['NAME'] ??
                        '',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatPrice(
                        productDetail['Price'] ?? widget.productData['Price']),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Mô tả sản phẩm',
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
                          productDetail['Description'] ??
                              widget.productData['Description'] ??
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
            context.read<CartProvider>().addItem(
                productDetail.isNotEmpty ? productDetail : widget.productData);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã thêm vào giỏ hàng')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Thêm vào giỏ hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
