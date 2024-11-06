import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:hpc_students/include/config.dart';
import 'package:flutter/services.dart';

class StudentMarketAddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? productToEdit;

  StudentMarketAddProductScreen({this.productToEdit});

  @override
  _StudentMarketAddProductScreenState createState() =>
      _StudentMarketAddProductScreenState();
}

class _StudentMarketAddProductScreenState
    extends State<StudentMarketAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;
  List<Map<String, dynamic>> categories = [];
  bool isLoading = false;
  Map<String, String> uploadedImages = {};
  bool isUploading = false;
  String uploadProgress = '';
  String _maSinhVien = '';
  Map<String, String> _sellerInfo = {};
  final _fullnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchCategories();

    if (widget.productToEdit != null) {
      _loadProductData();
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maSinhVien = prefs.getString('maSinhVien') ?? '';
      _fullnameController.text = prefs.getString('hoTen') ?? '';
      _phoneController.text = prefs.getString('dienThoai') ?? '';
      _addressController.text = prefs.getString('diaChi') ?? '';
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final url = SpreadsheetAPI.studentmarket;

      final response = await http.post(
        Uri.parse(url),
        body: {
          'copecute': SpreadApiKey,
          'action': 'getProducts',
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories =
              List<Map<String, dynamic>>.from(data['categories'] ?? []);
        });
      } else if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            setState(() {
              categories =
                  List<Map<String, dynamic>>.from(data['categories'] ?? []);
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        isUploading = true;
      });

      try {
        var formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(image.path),
        });

        var dio = Dio();
        dio.options.headers['Authorization'] = 'Client-ID b558035630d26ef';

        var response = await dio.post(
          'https://api.imgur.com/3/image.json',
          data: formData,
          onSendProgress: (sent, total) {
            setState(() {
              uploadProgress = '${((sent / total) * 100).toStringAsFixed(0)}%';
            });
          },
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          setState(() {
            uploadedImages['${uploadedImages.length + 1}'] =
                response.data['data']['link'];
          });
        } else {
          throw Exception('Upload failed');
        }
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Có lỗi khi tải ảnh lên')));
      } finally {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (uploadedImages.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Vui lòng thêm ít nhất 1 ảnh')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = SpreadsheetAPI.studentmarket;

      final sellerInfo = {
        'fullname': _fullnameController.text,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
      };

      final body = {
        'copecute': SpreadApiKey,
        'action':
            widget.productToEdit != null ? 'editProduct' : 'updateProduct',
        'mssv': _maSinhVien,
        'name': _nameController.text,
        'sellerInfo': json.encode(sellerInfo),
        'description': _descriptionController.text,
        'img': json.encode(uploadedImages),
        'price': _priceController.text,
        'category': _selectedCategory,
      };

      if (widget.productToEdit != null) {
        body['stt'] = widget.productToEdit!['STT'].toString();
      }

      final response = await http.post(
        Uri.parse(url),
        body: body,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(widget.productToEdit != null
                  ? 'Cập nhật sản phẩm thành công'
                  : 'Thêm sản phẩm thành công')));
        } else {
          throw Exception(data['message'] ?? 'Thao tác thất bại');
        }
      } else if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            if (data['success'] == true) {
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(widget.productToEdit != null
                      ? 'Cập nhật sản phẩm thành công'
                      : 'Thêm sản phẩm thành công')));
            } else {
              throw Exception(data['message'] ?? 'Thao tác thất bại');
            }
          }
        }
      } else {
        throw Exception('Không thể kết nối đến server');
      }
    } catch (e) {
      print('Error submitting form: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _loadProductData() {
    final product = widget.productToEdit!;

    _nameController.text = product['NAME'] ?? '';
    _descriptionController.text = product['Description'] ?? '';
    _priceController.text = product['Price']?.toString() ?? '';
    _selectedCategory = product['Category']?['STT']?.toString();

    try {
      if (product['IMG'] != null) {
        final imgJson = json.decode(product['IMG']);
        setState(() {
          uploadedImages = Map<String, String>.from(imgJson);
        });
      }
    } catch (e) {
      print('Error loading product images: $e');
    }

    try {
      if (product['SellerInformation'] != null) {
        final sellerInfo = product['SellerInformation'];
        _fullnameController.text = sellerInfo['fullname'] ?? '';
        _phoneController.text = sellerInfo['phoneNumber'] ?? '';
        _addressController.text = sellerInfo['address'] ?? '';
      }
    } catch (e) {
      print('Error loading seller information: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.productToEdit != null ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh sản phẩm
              Text(
                'Ảnh sản phẩm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...uploadedImages.entries.map((entry) => Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Image.network(
                                entry.value,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: Icon(Icons.close),
                                  color: Colors.white,
                                  onPressed: () {
                                    setState(() {
                                      uploadedImages.remove(entry.key);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (!isUploading && uploadedImages.length < 5)
                      InkWell(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 32),
                              Text('Thêm ảnh'),
                            ],
                          ),
                        ),
                      ),
                    if (isUploading)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(uploadProgress),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Thông tin người bán
              Text(
                'Thông tin người bán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _fullnameController,
                decoration: InputDecoration(
                  labelText: 'Họ tên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Thông tin sản phẩm
              Text(
                'Thông tin sản phẩm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên sản phẩm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên sản phẩm';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Danh mục',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category['STT'].toString(),
                    child: Text(category['NAME']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Giá',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  suffixText: 'đ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Giá không hợp lệ';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
                style: TextStyle(
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 24),

              // Nút đăng
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.productToEdit != null
                              ? 'Cập nhật sản phẩm'
                              : 'Đăng sản phẩm',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _fullnameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
