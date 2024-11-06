import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hpc_students/include/config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/Screen/StudentMarket/studentMarketAdd.dart';

class StudentMarketViewProduct extends StatefulWidget {
  final Map<String, dynamic> productData;

  StudentMarketViewProduct({required this.productData});

  @override
  _StudentMarketViewProductState createState() =>
      _StudentMarketViewProductState();
}

class _StudentMarketViewProductState extends State<StudentMarketViewProduct> {
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic> productDetail = {};
  List<String> imageUrls = [];
  int currentImageIndex = 0;
  final PageController _pageController = PageController();
  String _maSinhVien = '';

  @override
  void initState() {
    super.initState();
    _loadMaSinhVien();
    try {
      final imgJson = json.decode(widget.productData['IMG']);
      imageUrls = imgJson.values.cast<String>().toList();
    } catch (e) {
      if (widget.productData['IMG'] != null) {
        imageUrls = [widget.productData['IMG']];
      }
    }
    _fetchProductDetail();
  }

  Future<void> _loadMaSinhVien() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _maSinhVien = prefs.getString('maSinhVien') ?? '';
    });
  }

  Future<void> _fetchProductDetail() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
      });

      final url = SpreadsheetAPI.studentmarket;

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': SpreadApiKey,
          'action': 'getProduct',
          'stt': widget.productData['STT'].toString(),
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['IMG'] != null) {
          final imgJson = json.decode(data['IMG']);
          final newImageUrls = imgJson.values.cast<String>().toList();
          if (imageUrls.toString() != newImageUrls.toString()) {
            setState(() {
              imageUrls = newImageUrls;
            });
          }
        }

        setState(() {
          productDetail = data;
          isLoading = false;
          errorMessage = '';
        });
      } else if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (!mounted) return;

          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);

            if (data['IMG'] != null) {
              final imgJson = json.decode(data['IMG']);
              final newImageUrls = imgJson.values.cast<String>().toList();
              if (imageUrls.toString() != newImageUrls.toString()) {
                setState(() {
                  imageUrls = newImageUrls;
                });
              }
            }

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
      if (!mounted) return;

      setState(() {
        errorMessage = 'Có lỗi xảy ra khi tải thông tin sản phẩm.';
        isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Nếu không thể thực hiện cuộc gọi, hiển thị số điện thoại và nút copy
        if (mounted) {
          setState(() {
            errorMessage = 'Không thể thực hiện cuộc gọi';
          });
        }
      }
    } catch (e) {
      print('Error making phone call: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Không thể thực hiện cuộc gọi';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi tiết sản phẩm',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          if (productDetail['MSSV']?.toString() == _maSinhVien)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentMarketAddProductScreen(
                      productToEdit: productDetail,
                    ),
                  ),
                );

                if (result == true) {
                  // Refresh product details after edit
                  _fetchProductDetail();
                }
              },
            ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrls.isNotEmpty)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          currentImageIndex = index;
                        });
                      },
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.broken_image, size: 100),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: imageUrls.asMap().entries.map((entry) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentImageIndex == entry.key
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.withOpacity(0.5),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productDetail['NAME']?.toString() ??
                        widget.productData['NAME'] ??
                        '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${productDetail['Price']?.toString() ?? widget.productData['Price']?.toString() ?? '0'}đ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode ? Colors.greenAccent : Colors.green[700],
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      productDetail['Category']?['NAME'] ??
                          widget.productData['Category']?['NAME'] ??
                          'Chưa phân loại',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Thông tin người bán',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (productDetail['SellerInformation'] != null) ...[
                    Text(
                      'Họ tên: ${productDetail['SellerInformation']['fullname']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Địa chỉ: ${productDetail['SellerInformation']['address']}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                  SizedBox(height: 24),
                  Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    productDetail['Description'] ??
                        widget.productData['Description'] ??
                        '',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  if (isLoading) ...[
                    SizedBox(height: 24),
                    Center(
                      child: CircularProgressIndicator(),
                    ),
                    SizedBox(height: 24),
                  ],
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
        child: isLoading
            ? ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.5),
                ),
                child: Text(
                  'Liên hệ người bán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : errorMessage.isNotEmpty
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          productDetail['SellerInformation']?['phoneNumber'] ??
                              widget.productData['SellerInformation']
                                  ?['phoneNumber'] ??
                              'Không có số điện thoại',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () {
                          final phoneNumber = productDetail['SellerInformation']
                                  ?['phoneNumber'] ??
                              widget.productData['SellerInformation']
                                  ?['phoneNumber'];
                          if (phoneNumber != null) {
                            Clipboard.setData(ClipboardData(text: phoneNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã sao chép số điện thoại'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: () {
                      if (productDetail['SellerInformation'] != null) {
                        _makePhoneCall(
                            productDetail['SellerInformation']['phoneNumber']);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: Text(
                      'Liên hệ người bán',
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
