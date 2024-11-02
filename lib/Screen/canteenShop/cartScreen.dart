import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/Screen/canteenShop/cart_provider.dart';

class CartItem {
  final int stt;
  final String name;
  final String image;
  final double price;
  int quantity;

  CartItem({
    required this.stt,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'stt': stt,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      stt: json['stt'],
      name: json['name'],
      image: json['image'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
    );
  }
}

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartData = prefs.getString('cart_items');

      setState(() {
        if (cartData != null) {
          final List<dynamic> decodedData = json.decode(cartData);
          cartItems =
              decodedData.map((item) => CartItem.fromJson(item)).toList();
        }
        isLoading = false;
      });
    } catch (e) {
      print('Error loading cart items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = json.encode(
        cartItems.map((item) => item.toJson()).toList(),
      );
      await prefs.setString('cart_items', encodedData);
    } catch (e) {
      print('Error saving cart items: $e');
    }
  }

  void _updateQuantity(int index, int delta) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    setState(() {
      cartItems[index].quantity =
          (cartItems[index].quantity + delta).clamp(1, 99);
      _saveCartItems();
      cartProvider.updateFromCartScreen(cartItems);
    });
  }

  void _removeItem(int index) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final removedItem = cartItems[index];
    setState(() {
      cartItems.removeAt(index);
      _saveCartItems();
    });
    cartProvider.removeItem(removedItem.stt);
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
  }

  double get _totalPrice {
    return cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _placeOrder() async {
    try {
      setState(() {
        isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final mssv = prefs.getString('username');

      if (mssv == null) {
        _showSnackBar('Vui lòng đăng nhập lại để đặt hàng');
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Tạo object order từ cartItems
      Map<String, int> orderMap = {};
      for (var item in cartItems) {
        orderMap[item.stt.toString()] = item.quantity;
      }

      final url =
          'https://script.google.com/macros/s/AKfycbwLIYesYJgBbpOFWhCPxfpMSxnFrZZSbv9iMorkPyG0b8HkRKv6RLpqlsVrkEk5vGoh/exec';

      print('Placing order at URL: $url');
      print('Request body: ${{
        'copecute': 'MIiwxJTx8h3a3HLYvpYpWXsywFH71f5jYP1IQo8AMUwmZr9H7y',
        'action': 'placeOrder',
        'mssv': mssv,
        'order': json.encode(orderMap),
        'unitPrice': _totalPrice.toInt().toString(),
      }}');

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': 'MIiwxJTx8h3a3HLYvpYpWXsywFH71f5jYP1IQo8AMUwmZr9H7y',
          'action': 'placeOrder',
          'mssv': mssv,
          'order': json.encode(orderMap),
          'unitPrice': _totalPrice.toInt().toString(),
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      print("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response data: $data");

        if (data['success'] == true) {
          final cartProvider =
              Provider.of<CartProvider>(context, listen: false);
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('cart_items');

          setState(() {
            cartItems.clear();
          });
          cartProvider.updateFromCartScreen([]);

          _showSnackBar('Đặt hàng thành công');
        } else {
          _showSnackBar(data['message'] ?? 'Có lỗi xảy ra khi đặt hàng');
        }
      } else if (response.statusCode == 302) {
        print("Redirected to: ${response.headers['location']}");
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            print("Response data after redirect: $data");

            if (data['success'] == true) {
              final cartProvider =
                  Provider.of<CartProvider>(context, listen: false);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('cart_items');

              setState(() {
                cartItems.clear();
              });
              cartProvider.updateFromCartScreen([]);

              _showSnackBar('Đặt hàng thành công');
            } else {
              _showSnackBar(data['message'] ?? 'Có lỗi xảy ra khi đặt hàng');
            }
          }
        }
      } else {
        _showSnackBar('Không thể kết nối đến server');
      }
    } catch (e) {
      print('Error placing order: $e');
      _showSnackBar('Có lỗi xảy ra khi đặt hàng');
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
          'Giỏ hàng',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle:
            isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Giỏ hàng trống',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Card(
                      margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height * 0.02),
                      child: Padding(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.02),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.image,
                                width: MediaQuery.of(context).size.width * 0.2,
                                height: MediaQuery.of(context).size.width * 0.2,
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
                                  SizedBox(height: 4),
                                  Text(
                                    _formatPrice(item.price),
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () => _updateQuantity(index, -1),
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
                                  onPressed: () => _updateQuantity(index, 1),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline),
                              color: Colors.red,
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng tiền:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatPrice(_totalPrice),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                            'Đặt hàng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
