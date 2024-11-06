import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/Screen/imgur/viewImgur.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:hpc_students/include/config.dart';

class HomeImgurScreen extends StatefulWidget {
  @override
  _HomeImgurScreenState createState() => _HomeImgurScreenState();
}

class _HomeImgurScreenState extends State<HomeImgurScreen> {
  List<dynamic> imageList = [];
  bool isLoading = true;
  String errorMessage = '';
  int currentPage = 1;
  int totalPages = 1;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _captionController = TextEditingController();
  bool isUploading = false;
  String uploadProgress = '';

  @override
  void initState() {
    super.initState();
    print("Initializing HomeImgurScreen...");
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      setState(() {
        isLoading = true;
      });

      print("Fetching images for page: $currentPage");

      final url = SpreadsheetAPI.imgur;
      final body = {
        'copecute': SpreadApiKey,
        'action': 'getPage',
        'page': currentPage.toString(),
      };

      final response = await http.post(
        Uri.parse(url),
        body: body,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      print("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response data: $data");

        setState(() {
          imageList = data['images'] ?? [];
          totalPages = data['totalPages'] ?? 1;
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
              imageList = data['images'] ?? [];
              totalPages = data['totalPages'] ?? 1;
              isLoading = false;
              errorMessage = '';
            });
          }
        }
      } else {
        setState(() {
          errorMessage = 'Không có kết nối internet.';
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching images: $e");
      setState(() {
        errorMessage = 'Có lỗi xảy ra khi tải ảnh.';
        isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      _fetchImages();
    }
  }

  void _prevPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      _fetchImages();
    }
  }

  void _goToFirstPage() {
    if (currentPage != 1) {
      setState(() {
        currentPage = 1;
      });
      _fetchImages();
    }
  }

  void _goToLastPage() {
    if (currentPage != totalPages) {
      setState(() {
        currentPage = totalPages;
      });
      _fetchImages();
    }
  }

  Future<void> _showAddPostDialog() async {
    String? imageUrl;
    bool isPosting = false;

    setState(() {
      isUploading = false;
      uploadProgress = '';
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                AlertDialog(
                  title: Text('Thêm bài viết mới'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (imageUrl != null) ...[
                          Image.network(
                            imageUrl!,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: 16),
                        ],
                        if (isUploading) ...[
                          LinearProgressIndicator(
                            value: double.tryParse(
                                        uploadProgress.replaceAll('%', ''))
                                    ?.toDouble() ??
                                0 / 100,
                          ),
                          SizedBox(height: 8),
                          Text('Đang tải lên: $uploadProgress'),
                          SizedBox(height: 16),
                        ],
                        if (!isUploading && imageUrl == null)
                          ElevatedButton(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery);

                              if (image != null) {
                                setState(() {
                                  isUploading = true;
                                });

                                try {
                                  // Upload to Imgur
                                  var formData = FormData.fromMap({
                                    'image': await MultipartFile.fromFile(
                                        image.path),
                                  });

                                  var dio = Dio();
                                  dio.options.headers['Authorization'] =
                                      'Client-ID b558035630d26ef';

                                  var response = await dio.post(
                                    'https://api.imgur.com/3/image.json',
                                    data: formData,
                                    onSendProgress: (sent, total) {
                                      setState(() {
                                        uploadProgress =
                                            '${((sent / total) * 100).toStringAsFixed(0)}%';
                                      });
                                    },
                                  );

                                  if (response.statusCode == 200 &&
                                      response.data['success'] == true) {
                                    imageUrl = response.data['data']['link'];
                                    setState(() {
                                      isUploading = false;
                                    });
                                  } else {
                                    throw Exception('Upload failed');
                                  }
                                } catch (e) {
                                  print('Error uploading image: $e');
                                  setState(() {
                                    isUploading = false;
                                  });
                                  Navigator.of(context).pop();
                                  _showSnackBar('Có lỗi khi tải ảnh lên');
                                }
                              }
                            },
                            child: Text('Chọn ảnh'),
                          ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _captionController,
                          decoration: InputDecoration(
                            hintText: 'Nhập mô tả...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isPosting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _captionController.clear();
                            },
                      child: Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: (imageUrl == null || isUploading || isPosting)
                          ? null
                          : () async {
                              try {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                String? username = prefs.getString('username');

                                if (username == null) {
                                  _showSnackBar(
                                      'Vui lòng đăng nhập để đăng bài');
                                  return;
                                }

                                setState(() {
                                  isPosting = true;
                                });

                                print("Posting new image with URL: $imageUrl");

                                final url = SpreadsheetAPI.imgur;
                                final body = {
                                  'copecute': SpreadApiKey,
                                  'action': 'addImage',
                                  'username': username,
                                  'caption': _captionController.text,
                                  'img': imageUrl,
                                };

                                print("Sending request with body: $body");

                                final response = await http.post(
                                  Uri.parse(url),
                                  body: body,
                                  headers: {
                                    'Content-Type':
                                        'application/x-www-form-urlencoded',
                                  },
                                );

                                print(
                                    "Response status: ${response.statusCode}");

                                bool success = false;

                                if (response.statusCode == 200) {
                                  final data = json.decode(response.body);
                                  print("Response data: $data");

                                  if (data['success'] == true) {
                                    success = true;
                                  } else {
                                    _showSnackBar(
                                        data['error'] ?? 'Có lỗi xảy ra');
                                  }
                                } else if (response.statusCode == 302) {
                                  print(
                                      "Redirected to: ${response.headers['location']}");
                                  final redirectUrl =
                                      response.headers['location'];
                                  if (redirectUrl != null) {
                                    final redirectResponse =
                                        await http.get(Uri.parse(redirectUrl));
                                    if (redirectResponse.statusCode == 200) {
                                      final data =
                                          json.decode(redirectResponse.body);
                                      print(
                                          "Response data after redirect: $data");

                                      if (data['success'] == true) {
                                        success = true;
                                      } else {
                                        _showSnackBar(
                                            data['error'] ?? 'Có lỗi xảy ra');
                                      }
                                    } else {
                                      throw Exception(
                                          'Failed to load data after redirect');
                                    }
                                  }
                                } else {
                                  _showSnackBar('Không thể kết nối đến server');
                                }

                                if (success) {
                                  Navigator.of(context).pop();
                                  _captionController.clear();
                                  _showSnackBar('Đăng bài thành công');
                                  await _fetchImages();
                                }
                              } catch (e) {
                                print('Error posting image: $e');
                                _showSnackBar('Có lỗi khi đăng bài');
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    isPosting = false;
                                  });
                                }
                              }
                            },
                      child: isPosting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            )
                          : Text('Đăng'),
                    ),
                  ],
                ),
                if (isPosting)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thư viện ảnh'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_photo_alternate),
            onPressed: _showAddPostDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchImages,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchImages,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && imageList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải ảnh...'),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              onPressed: _fetchImages,
              child: Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFF2d59a4),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView(
          controller: _scrollController,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Text(
                'Mọi hình ảnh do thành viên chia sẻ, hãy báo cáo vi phạm nếu có nội dung không phù hợp',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: imageList.length,
              itemBuilder: (context, index) {
                final image = imageList[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewImgurScreen(
                            imageData: image,
                          ),
                        ),
                      );

                      if (result == true) {
                        _fetchImages();
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(10)),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  image['img'] ?? '',
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child:
                                            Icon(Icons.broken_image, size: 40),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Người đăng: ${image['Username']?.toString() ?? 'Ẩn danh'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  image['Caption']?.toString() ?? '',
                                  style: TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.favorite_border, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '${(image['likes'] as List?)?.length ?? 0}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    SizedBox(width: 16),
                                    Icon(Icons.comment_outlined, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '${(image['comments'] as List?)?.length ?? 0}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: currentPage > 1 ? _prevPage : null,
                  ),
                  Text(
                    'Trang $currentPage/$totalPages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: currentPage < totalPages ? _nextPage : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
