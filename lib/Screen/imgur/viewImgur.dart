import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hpc_students/include/config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class ViewImgurScreen extends StatefulWidget {
  final Map<String, dynamic> imageData;

  ViewImgurScreen({required this.imageData});

  @override
  _ViewImgurScreenState createState() => _ViewImgurScreenState();
}

class _ViewImgurScreenState extends State<ViewImgurScreen> {
  List<dynamic> comments = [];
  List<dynamic> likes = [];
  bool isLoading = true;
  String errorMessage = '';
  String username = '';
  bool isLiked = false;
  bool isOwner = false;
  final TextEditingController _commentController = TextEditingController();
  bool isSaving = false;
  final TextEditingController _reportTitleController = TextEditingController();
  final TextEditingController _reportContentController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    print("Initializing ViewImgurScreen...");
    _loadUsername();
    setState(() {
      comments = widget.imageData['comments'] ?? [];
      likes = widget.imageData['likes'] ?? [];
      isLoading = false;
    });
  }

  Future<void> _loadUsername() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedUsername = prefs.getString('username');
      if (savedUsername != null) {
        setState(() {
          username = savedUsername;
          isLiked = likes.contains(savedUsername);
          isOwner = savedUsername.toString() ==
              widget.imageData['Username']?.toString();
        });
        print("Loaded username: $savedUsername");
        print("Is owner: $isOwner");
      } else {
        print("No username found in SharedPreferences");
      }
    } catch (e) {
      print("Error loading username: $e");
      _showSnackBar('Có lỗi khi tải thông tin người dùng');
    }
  }

  Future<void> _handleLike() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedUsername = prefs.getString('username');

      if (savedUsername == null || savedUsername.isEmpty) {
        _showSnackBar('Vui lòng đăng nhập để thích ảnh');
        return;
      }

      setState(() {
        isLoading = true;
      });

      print("Handling like for image STT: ${widget.imageData['STT']}");

      final url =
          'https://script.google.com/macros/s/AKfycbyG9y5g_PXeKbIDm_y6t2MyVzH9KW6u2FKPOrwyX6DPcooay1T9Olm9EdXnS1d4jAhC/exec';
      final body = {
        'copecute': '$ggsapiKey',
        'action': 'likeImage',
        'stt': widget.imageData['STT'].toString(),
        'username': savedUsername,
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

        if (data['success'] == true) {
          setState(() {
            if (isLiked) {
              likes.remove(savedUsername);
            } else {
              likes.add(savedUsername);
            }
            isLiked = !isLiked;
          });
          _showSnackBar(isLiked ? 'Đã thích ảnh' : 'Đã bỏ thích ảnh');
        } else {
          _showSnackBar(data['message'] ?? 'Có lỗi xảy ra');
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
              setState(() {
                if (isLiked) {
                  likes.remove(savedUsername);
                } else {
                  likes.add(savedUsername);
                }
                isLiked = !isLiked;
              });
              _showSnackBar(isLiked ? 'Đã thích ảnh' : 'Đã bỏ thích ảnh');
            } else {
              _showSnackBar(data['message'] ?? 'Có lỗi xảy ra');
            }
          } else {
            throw Exception('Failed to load data after redirect');
          }
        }
      } else {
        _showSnackBar('Không thể kết nối đến server');
      }
    } catch (e) {
      print('Error liking image: $e');
      _showSnackBar('Có lỗi xảy ra khi thích ảnh');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleDelete() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa ảnh này không?'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'Xóa',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      setState(() {
        isLoading = true;
      });

      print("Deleting image STT: ${widget.imageData['STT']}");

      final url =
          'https://script.google.com/macros/s/AKfycbyG9y5g_PXeKbIDm_y6t2MyVzH9KW6u2FKPOrwyX6DPcooay1T9Olm9EdXnS1d4jAhC/exec';
      final body = {
        'copecute': '$ggsapiKey',
        'action': 'deleteImage',
        'stt': widget.imageData['STT'].toString(),
        'username': username,
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

        if (data['success'] == true) {
          _showSnackBar('Đã xóa ảnh thành công');
          Navigator.of(context).pop(true);
        } else {
          _showSnackBar(data['error'] ?? 'Có lỗi xảy ra khi xóa ảnh');
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
              _showSnackBar('Đã xóa ảnh thành công');
              Navigator.of(context).pop(true);
            } else {
              _showSnackBar(data['error'] ?? 'Có lỗi xảy ra khi xóa ảnh');
            }
          } else {
            throw Exception('Failed to load data after redirect');
          }
        }
      } else {
        _showSnackBar('Không thể kết nối đến server');
      }
    } catch (e) {
      print('Error deleting image: $e');
      _showSnackBar('Có lỗi xảy ra khi xóa ảnh');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleComment() async {
    if (_commentController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập nội dung bình luận');
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedUsername = prefs.getString('username');

      if (savedUsername == null || savedUsername.isEmpty) {
        _showSnackBar('Vui lòng đăng nhập để bình luận');
        return;
      }

      setState(() {
        isLoading = true;
      });

      print("Adding comment for image STT: ${widget.imageData['STT']}");

      final url =
          'https://script.google.com/macros/s/AKfycbyG9y5g_PXeKbIDm_y6t2MyVzH9KW6u2FKPOrwyX6DPcooay1T9Olm9EdXnS1d4jAhC/exec';
      final body = {
        'copecute': '$ggsapiKey',
        'action': 'commentImage',
        'stt': widget.imageData['STT'].toString(),
        'username': savedUsername,
        'comment': _commentController.text.trim(),
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

        if (data['success'] == true) {
          setState(() {
            comments.add({
              'username': savedUsername,
              'comment': _commentController.text.trim(),
              'timestamp': DateTime.now().toIso8601String(),
            });
            _commentController.clear(); // Xóa nội dung input
          });
          _showSnackBar('Đã thêm bình luận');
        } else {
          _showSnackBar(data['error'] ?? 'Có lỗi xảy ra khi thêm bình luận');
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
              setState(() {
                comments.add({
                  'username': savedUsername,
                  'comment': _commentController.text.trim(),
                  'timestamp': DateTime.now().toIso8601String(),
                });
                _commentController.clear(); // Xóa nội dung input
              });
              _showSnackBar('Đã thêm bình luận');
            } else {
              _showSnackBar(
                  data['error'] ?? 'Có lỗi xảy ra khi thêm bình luận');
            }
          } else {
            throw Exception('Failed to load data after redirect');
          }
        }
      } else {
        _showSnackBar('Không thể kết nối đến server');
      }
    } catch (e) {
      print('Error adding comment: $e');
      _showSnackBar('Có lỗi xảy ra khi thêm bình luận');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveImage() async {
    try {
      setState(() {
        isSaving = true;
      });

      // Kiểm tra quyền truy cập storage
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnackBar('Cần cấp quyền truy cập bộ nhớ để lưu ảnh');
        return;
      }

      // Tạo thư mục trong Downloads
      final downloadsDir =
          Directory('/storage/emulated/0/Download/HPC-Students/imgur');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Tạo tên file từ URL
      final url = widget.imageData['img'];
      final fileName = url.split('/').last;
      final filePath = '${downloadsDir.path}/$fileName';

      print('Saving image to: $filePath');

      // Download file
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );

      _showSnackBar('Đã lưu ảnh vào ${downloadsDir.path}');
    } catch (e) {
      print('Error saving image: $e');
      _showSnackBar('Có lỗi khi lưu ảnh');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> _showReportDialog() async {
    bool isReporting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                AlertDialog(
                  title: Text('Báo cáo vi phạm'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _reportTitleController,
                          decoration: InputDecoration(
                            labelText: 'Tiêu đề',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _reportContentController,
                          decoration: InputDecoration(
                            labelText: 'Nội dung',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isReporting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _reportTitleController.clear();
                              _reportContentController.clear();
                            },
                      child: Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: isReporting
                          ? null
                          : () async {
                              if (_reportTitleController.text.trim().isEmpty ||
                                  _reportContentController.text
                                      .trim()
                                      .isEmpty) {
                                _showSnackBar(
                                    'Vui lòng nhập đầy đủ thông tin báo cáo');
                                return;
                              }

                              try {
                                setState(() {
                                  isReporting = true;
                                });

                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                String? savedUsername =
                                    prefs.getString('username');

                                if (savedUsername == null) {
                                  _showSnackBar(
                                      'Vui lòng đăng nhập để báo cáo');
                                  return;
                                }

                                final url =
                                    'https://script.google.com/macros/s/AKfycbyG9y5g_PXeKbIDm_y6t2MyVzH9KW6u2FKPOrwyX6DPcooay1T9Olm9EdXnS1d4jAhC/exec';
                                final body = {
                                  'copecute': '$ggsapiKey',
                                  'action': 'reportImage',
                                  'stt': widget.imageData['STT'].toString(),
                                  'username': savedUsername,
                                  'title': _reportTitleController.text.trim(),
                                  'content':
                                      _reportContentController.text.trim(),
                                };

                                final response = await http.post(
                                  Uri.parse(url),
                                  body: body,
                                  headers: {
                                    'Content-Type':
                                        'application/x-www-form-urlencoded',
                                  },
                                );

                                if (response.statusCode == 200) {
                                  final data = json.decode(response.body);
                                  if (data['success'] == true) {
                                    Navigator.of(context).pop();
                                    _reportTitleController.clear();
                                    _reportContentController.clear();
                                    _showSnackBar('Đã gửi báo cáo');
                                  } else {
                                    _showSnackBar(
                                        data['error'] ?? 'Có lỗi xảy ra');
                                  }
                                } else if (response.statusCode == 302) {
                                  final redirectUrl =
                                      response.headers['location'];
                                  if (redirectUrl != null) {
                                    final redirectResponse =
                                        await http.get(Uri.parse(redirectUrl));
                                    if (redirectResponse.statusCode == 200) {
                                      final data =
                                          json.decode(redirectResponse.body);
                                      if (data['success'] == true) {
                                        Navigator.of(context).pop();
                                        _reportTitleController.clear();
                                        _reportContentController.clear();
                                        _showSnackBar('Đã gửi báo cáo');
                                      } else {
                                        _showSnackBar(
                                            data['error'] ?? 'Có lỗi xảy ra');
                                      }
                                    }
                                  }
                                }
                              } catch (e) {
                                print('Error reporting: $e');
                                _showSnackBar('Có lỗi khi gửi báo cáo');
                              } finally {
                                setState(() {
                                  isReporting = false;
                                });
                              }
                            },
                      child: isReporting
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
                          : Text('Gửi'),
                    ),
                  ],
                ),
                if (isReporting)
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

  @override
  void dispose() {
    _commentController.dispose();
    _reportTitleController.dispose();
    _reportContentController.dispose();
    super.dispose();
  }

  String _formatTimestamp(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'Thời gian không hợp lệ';
    }
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
        title: Text('Chi tiết ảnh'),
        actions: [
          IconButton(
            icon: Icon(Icons.report),
            onPressed: _showReportDialog,
            tooltip: 'Báo cáo vi phạm',
          ),
          if (!isSaving)
            IconButton(
              icon: Icon(Icons.save_alt),
              onPressed: _saveImage,
              tooltip: 'Lưu ảnh',
            ),
          if (isOwner)
            IconButton(
              icon: Icon(Icons.delete),
              color: Colors.red,
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          widget.imageData['img'] ?? '',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.broken_image, size: 100),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipOval(
                                  child: Image.asset(
                                    'assets/avatar.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.imageData['Username']
                                                ?.toString() ??
                                            'Ẩn danh',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _formatTimestamp(widget
                                                .imageData['timestamp']
                                                ?.toString() ??
                                            ''),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              widget.imageData['Caption']?.toString() ?? '',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                InkWell(
                                  onTap: _handleLike,
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isLiked ? Colors.red : null,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '${likes.length} lượt thích',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 24),
                                Icon(Icons.comment_outlined),
                                SizedBox(width: 8),
                                Text(
                                  '${comments.length} bình luận',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            if (comments.isNotEmpty) ...[
                              SizedBox(height: 24),
                              Text(
                                'Bình luận',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              ...comments
                                  .map((comment) => Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipOval(
                                              child: Image.asset(
                                                'assets/avatar.png',
                                                width: 32,
                                                height: 32,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        comment['username']
                                                                ?.toString() ??
                                                            'Ẩn danh',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        _formatTimestamp(comment[
                                                                    'timestamp']
                                                                ?.toString() ??
                                                            ''),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(comment['comment']
                                                          ?.toString() ??
                                                      ''),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Thêm bình luận...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _handleComment,
                      color: Color(0xFF2d59a4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading || isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    if (isSaving) ...[
                      SizedBox(height: 16),
                      Text(
                        'Đang lưu ảnh...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
