import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hpc_students/Screen/canteenShop/cartScreen.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  CartProvider() {
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString('cart_items');

    if (cartData != null) {
      final List<dynamic> decodedData = json.decode(cartData);
      _items = decodedData.map((item) => CartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      _items.map((item) => item.toJson()).toList(),
    );
    await prefs.setString('cart_items', encodedData);
  }

  void addItem(Map<String, dynamic> product) {
    final existingItemIndex =
        _items.indexWhere((item) => item.stt == product['STT']);

    if (existingItemIndex != -1) {
      _items[existingItemIndex].quantity++;
    } else {
      _items.add(CartItem(
        stt: product['STT'],
        name: product['NAME'],
        image: product['IMG'],
        price: (product['Price'] as num).toDouble(),
      ));
    }

    _saveCartItems();
    notifyListeners();
  }

  void updateFromCartScreen(List<CartItem> newItems) {
    _items = newItems;
    _saveCartItems();
    notifyListeners();
  }

  void removeItem(int stt) {
    _items.removeWhere((item) => item.stt == stt);
    _saveCartItems();
    notifyListeners();
  }
}
