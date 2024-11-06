import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LibraryCartItem {
  final int stt;
  final String name;
  final String image;
  int quantity;

  LibraryCartItem({
    required this.stt,
    required this.name,
    required this.image,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'stt': stt,
      'name': name,
      'image': image,
      'quantity': quantity,
    };
  }

  factory LibraryCartItem.fromJson(Map<String, dynamic> json) {
    return LibraryCartItem(
      stt: json['stt'],
      name: json['name'],
      image: json['image'],
      quantity: json['quantity'],
    );
  }
}

class LibraryCartProvider with ChangeNotifier {
  List<LibraryCartItem> _items = [];

  List<LibraryCartItem> get items => _items;

  int get itemCount => _items.length;

  LibraryCartProvider() {
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString('library_cart_items');

    if (cartData != null) {
      final List<dynamic> decodedData = json.decode(cartData);
      _items =
          decodedData.map((item) => LibraryCartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      _items.map((item) => item.toJson()).toList(),
    );
    await prefs.setString('library_cart_items', encodedData);
  }

  void addItem(Map<String, dynamic> book) {
    final existingItemIndex =
        _items.indexWhere((item) => item.stt == book['STT']);

    if (existingItemIndex != -1) {
      _items[existingItemIndex].quantity++;
    } else {
      _items.add(LibraryCartItem(
        stt: book['STT'],
        name: book['NAME'],
        image: book['IMG'],
      ));
    }

    _saveCartItems();
    notifyListeners();
  }

  void updateFromCartScreen(List<LibraryCartItem> newItems) {
    _items = newItems;
    _saveCartItems();
    notifyListeners();
  }

  void removeItem(int stt) {
    _items.removeWhere((item) => item.stt == stt);
    _saveCartItems();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveCartItems();
    notifyListeners();
  }
}
