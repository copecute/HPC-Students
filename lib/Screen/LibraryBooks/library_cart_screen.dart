import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/Screen/LibraryBooks/library_cart_provider.dart';
import 'package:hpc_students/include/config.dart';

class LibraryCartScreen extends StatefulWidget {
  @override
  _LibraryCartScreenState createState() => _LibraryCartScreenState();
}

class _LibraryCartScreenState extends State<LibraryCartScreen> {
  bool isLoading = false;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final dienThoai = prefs.getString('dienThoai') ?? '';
    setState(() {
      _phoneController.text = dienThoai;
    });
  }

  Future<void> _borrowBooks() async {
    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập số điện thoại');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final mssv = prefs.getString('username');
      final hoTen = prefs.getString('hoTen') ?? '';

      if (mssv == null) {
        _showSnackBar('Vui lòng đăng nhập lại để mượn sách');
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Tạo object order từ cartItems
      Map<String, int> orderMap = {};
      final cartProvider =
          Provider.of<LibraryCartProvider>(context, listen: false);
      for (var item in cartProvider.items) {
        orderMap[item.stt.toString()] = item.quantity;
      }

      // Tạo object thông tin người mượn
      Map<String, String> ordererInfo = {
        'fullname': hoTen,
        'phoneNumber': _phoneController.text.trim(),
      };

      final url = SpreadsheetAPI.libraryBooks;

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': SpreadApiKey,
          'action': 'Borrowing',
          'mssv': mssv,
          'ordererInfo': json.encode(ordererInfo),
          'order': json.encode(orderMap),
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          cartProvider.clearCart();
          _showSnackBar('Đăng ký mượn sách thành công');
          Navigator.pop(context);
        } else {
          _showSnackBar(data['message'] ?? 'Có lỗi xảy ra khi mượn sách');
        }
      } else if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            if (data['success'] == true) {
              cartProvider.clearCart();
              _showSnackBar('Đăng ký mượn sách thành công');
              Navigator.pop(context);
            } else {
              _showSnackBar(data['message'] ?? 'Có lỗi xảy ra khi mượn sách');
            }
          }
        }
      } else {
        _showSnackBar('Không thể kết nối đến server');
      }
    } catch (e) {
      print('Error borrowing books: $e');
      _showSnackBar('Có lỗi xảy ra khi mượn sách');
    } finally {
      setState(() {
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
    final cartProvider = Provider.of<LibraryCartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Giỏ sách',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: cartProvider.items.length,
              itemBuilder: (context, index) {
                final item = cartProvider.items[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.image,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        setState(() {
                                          item.quantity--;
                                        });
                                        cartProvider.updateFromCartScreen(
                                            cartProvider.items);
                                      }
                                    },
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () {
                                      setState(() {
                                        item.quantity++;
                                      });
                                      cartProvider.updateFromCartScreen(
                                          cartProvider.items);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline),
                          color: Colors.red,
                          onPressed: () => cartProvider.removeItem(item.stt),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
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
            child: Column(
              children: [
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cartProvider.items.isEmpty || isLoading
                        ? null
                        : _borrowBooks,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Mượn sách',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
