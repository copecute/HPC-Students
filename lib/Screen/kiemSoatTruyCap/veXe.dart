import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import for SVG support
import 'package:http/http.dart' as http; // Import http package for API calls
import 'dart:convert'; // Import for JSON decoding
import 'package:hpc_students/include/config.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences
import 'package:hpc_students/Screen/loginScreen.dart'; // Import LoginScreen

class VeXeScreen extends StatefulWidget {
  @override
  _VeXeScreenState createState() => _VeXeScreenState();
}

class _VeXeScreenState extends State<VeXeScreen> {
  String _maThe = ''; // Initialize maThe as empty
  String _soTien = '';
  String _donGia = '';
  int _lanQuet = 0; // Initialize lanQuet as an integer
  bool _isLoading = true; // Loading state
  bool _isButtonLoading = false; // Loading state for the button
  bool _isCardNotRegistered = false; // State for card registration message
  final TextEditingController _donGiaController =
      TextEditingController(); // Controller for DonGia input

  @override
  void initState() {
    super.initState();
    print("Initializing VeXeScreen..."); // Debug print
    _loadUsername(); // Load username on initialization
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username'); // Get cached username
    print("Loaded username: $username"); // Debug print

    if (username != null) {
      setState(() {
        _maThe = username; // Set maThe to username
      });
      print("Username found, setting maThe to: $_maThe"); // Debug print
      await _fetchTicketInfo(); // Fetch ticket information
    } else {
      // Navigate to LoginScreen if no username is found
      print("No username found, navigating to LoginScreen."); // Debug print
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Future<void> _fetchTicketInfo() async {
    setState(() {
      _isLoading = true; // Set loading state
    });

    try {
      print("Fetching ticket info for maThe: $_maThe"); // Debug print

      // Prepare the URL and the body for the POST request
      final url =
          'https://script.google.com/macros/s/AKfycbykSJAxuza1q-pPmFOez8wgdqxQiaeInLuJL_ERs1Q3Ean7DGb3-aYXBzDRsbjxIbG9/exec';
      final body = {
        'maThe': _maThe,
        'action': 'get',
        'copecute': ggsapiKey,
      };

      // Make the POST request
      final response = await http.post(
        Uri.parse(url),
        body: body,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      print("Response status: ${response.statusCode}"); // Debug print
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response data: $data"); // Debug print
        setState(() {
          _soTien =
              data['SoTien']?.toString() ?? '0'; // Use null-aware operator
          _donGia =
              data['DonGia']?.toString() ?? '0'; // Use null-aware operator
          _lanQuet = data['LanQuet'] ?? 0; // Default to 0 if null
          _isCardNotRegistered = false; // Reset card registration state
        });
      } else if (response.statusCode == 302) {
        // Handle redirection
        print("Redirected to: ${response.headers['location']}"); // Debug print
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          // Follow the redirect
          final redirectResponse = await http.get(Uri.parse(redirectUrl));
          if (redirectResponse.statusCode == 200) {
            final data = json.decode(redirectResponse.body);
            print("Response data after redirect: $data"); // Debug print
            // Check for success message
            if (data['STT'] != null) {
              setState(() {
                _soTien = data['SoTien']?.toString() ??
                    '0'; // Use null-aware operator
                _donGia = data['DonGia']?.toString() ??
                    '0'; // Use null-aware operator
                _lanQuet = data['LanQuet'] ?? 0; // Default to 0 if null
                _isCardNotRegistered = false; // Reset card registration state
              });

              print("Current SoTien: $_soTien"); // Debug print
              print("Current DonGia: $_donGia"); // Debug print
            } else if (data['error'] != null) {
              _isCardNotRegistered = true;
              _showSnackBar(data['error']); // Show error messages
            }
          }
        }
      } else {
        print(
            "Failed to load ticket info, status code: ${response.statusCode}"); // Debug print
        _showSnackBar(
            "Không có kết nối internet."); // Show internet connection error
      }
    } catch (e) {
      print("Error fetching ticket info: $e"); // Debug print
      _showSnackBar(
          "Có lỗi xảy ra khi lấy thông tin thẻ."); // Show error message
    } finally {
      // Ensure loading state is reset
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Future<void> _quetThe() async {
    print("Quét thẻ for maThe: $_maThe"); // Debug print

    // Prepare the URL and the body for the POST request
    final url =
        'https://script.google.com/macros/s/AKfycbykSJAxuza1q-pPmFOez8wgdqxQiaeInLuJL_ERs1Q3Ean7DGb3-aYXBzDRsbjxIbG9/exec';
    final body = {
      'maThe': _maThe,
      'copecute': ggsapiKey,
      'action': 'quetthe',
    };

    // Show loading indicator on the button
    setState(() {
      _isButtonLoading = true;
    });

    // Make the POST request
    final response = await http.post(
      Uri.parse(url),
      body: body,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    print("Quét thẻ response status: ${response.statusCode}"); // Debug print
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Quét thẻ response data: $data"); // Debug print
      // Check for success message
      if (data['success'] == true) {
        // Debug prints to check values before parsing
        print("Current SoTien: $_soTien"); // Debug print
        print("Current DonGia: $_donGia"); // Debug print

        // Check if _soTien and _donGia are valid numbers
        if (_soTien.isNotEmpty && _donGia.isNotEmpty) {
          try {
            setState(() {
              _lanQuet += 1; // Increment lanQuet
              _soTien = (int.parse(_soTien) - int.parse(_donGia))
                  .toString(); // Deduct donGia from soTien
              _showSnackBar("Quét thẻ thành công!"); // Show success message
            });
          } catch (e) {
            print("Error parsing numbers: $e"); // Debug print
            _showSnackBar(
                "Có lỗi xảy ra khi xử lý số tiền."); // Show error message
          }
        } else {
          _showSnackBar(
              "Số tiền hoặc đơn giá không hợp lệ."); // Show error message
        }
      } else if (data['error'] != null) {
        // Handle error messages
        _showSnackBar(data['error']);
      }
    } else if (response.statusCode == 302) {
      // Handle redirection
      print("Redirected to: ${response.headers['location']}"); // Debug print
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        // Follow the redirect
        final redirectResponse = await http.get(Uri.parse(redirectUrl));
        if (redirectResponse.statusCode == 200) {
          final data = json.decode(redirectResponse.body);
          print("Quét thẻ response data after redirect: $data"); // Debug print
          // Check for success message
          if (data['success'] == true) {
            setState(() {
              _lanQuet += 1; // Increment lanQuet
              // Check if _soTien and _donGia are valid numbers
              if (_soTien.isNotEmpty && _donGia.isNotEmpty) {
                try {
                  _soTien = (int.parse(_soTien) - int.parse(_donGia))
                      .toString(); // Deduct donGia from soTien
                  _showSnackBar("Quét thẻ thành công!"); // Show success message
                } catch (e) {
                  print(
                      "Error parsing numbers after redirect: $e"); // Debug print
                  _showSnackBar(
                      "Có lỗi xảy ra khi xử lý số tiền."); // Show error message
                }
              } else {
                _showSnackBar(
                    "Số tiền hoặc đơn giá không hợp lệ."); // Show error message
              }
            });
          } else if (data['error'] != null) {
            _showSnackBar(data['error']); // Show error messages
          }
        } else {
          print(
              "Failed to quét thẻ after redirect, status code: ${redirectResponse.statusCode}"); // Debug print
        }
      }
    } else {
      print(
          "Failed to quét thẻ, status code: ${response.statusCode}"); // Debug print
      _showSnackBar(
          "Không có kết nối internet."); // Show internet connection error
    }

    // Stop loading indicator on the button
    setState(() {
      _isButtonLoading = false;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _registerCard() {
    // Set the controller's text to the current donGia value
    _donGiaController.text = _donGia;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String soTien = '';
        return AlertDialog(
          title: Text('Kê khai thông tin thẻ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Mã thẻ: $_maThe"),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(labelText: 'Số tiền'),
                onChanged: (value) {
                  soTien = value;
                },
              ),
              SizedBox(height: 20),
              TextField(
                controller:
                    _donGiaController, // Set the controller for DonGia input
                decoration: InputDecoration(labelText: 'Đơn giá'),
                onChanged: (value) {
                  // Optionally, you can update donGia variable if needed
                  // donGia = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                await _submitCardInfo(soTien,
                    _donGiaController.text); // Use the controller's text
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Gửi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitCardInfo(String soTien, String donGia) async {
    final url =
        'https://script.google.com/macros/s/AKfycbykSJAxuza1q-pPmFOez8wgdqxQiaeInLuJL_ERs1Q3Ean7DGb3-aYXBzDRsbjxIbG9/exec?action=update&maThe=$_maThe&soTien=$soTien&donGia=$donGia&copecute=$ggsapiKey';

    // Show loading indicator
    setState(() {
      _isLoading = true; // Set loading state
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    print(
        "Submit card info response status: ${response.statusCode}"); // Debug print
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        _showSnackBar("Kê khai thành công!"); // Show success message
        await _fetchTicketInfo(); // Fetch updated ticket info
      } else {
        _showSnackBar(data['error'] ?? "Có lỗi xảy ra."); // Show error message
      }
    } else if (response.statusCode == 302) {
      // Handle redirection
      print("Redirected to: ${response.headers['location']}"); // Debug print
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        // Follow the redirect
        final redirectResponse = await http.get(Uri.parse(redirectUrl));
        if (redirectResponse.statusCode == 200) {
          final data = json.decode(redirectResponse.body);
          if (data['success'] == true) {
            _showSnackBar("Kê khai thành công!"); // Show success message
            await _fetchTicketInfo(); // Fetch updated ticket info
          } else {
            _showSnackBar(
                data['error'] ?? "Có lỗi xảy ra."); // Show error message
          }
        } else {
          print(
              "Failed to submit card info after redirect, status code: ${redirectResponse.statusCode}"); // Debug print
          _showSnackBar(
              "Không có kết nối internet."); // Show internet connection error
        }
      }
    } else {
      _showSnackBar(
          "Không có kết nối internet."); // Show internet connection error
    }

    // Stop loading indicator
    setState(() {
      _isLoading = false; // Reset loading state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin vé xe'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings), // Settings icon
            onPressed: () {
              _registerCard(); // Show the register card dialog
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SvgPicture.asset(
            'assets/AccessControl/Parking.svg',
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FractionallySizedBox(
                    widthFactor:
                        0.8, // Đặt chiều rộng Card là 80% chiều rộng màn hình
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 50),
                                  CircularProgressIndicator(), // Hiển thị chỉ báo loading
                                  SizedBox(height: 50),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isCardNotRegistered) ...[
                                    Text(
                                      "Bạn chưa khai thông tin thẻ",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        _registerCard();
                                      },
                                      child: Text('Kê khai'),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor:
                                            Color(0xFF2d59a4), // Màu chữ
                                      ),
                                    ),
                                  ] else ...[
                                    Text('Mã thẻ: $_maThe',
                                        style: TextStyle(fontSize: 18)),
                                    SizedBox(height: 8),
                                    Text('Số tiền: $_soTien',
                                        style: TextStyle(fontSize: 18)),
                                    SizedBox(height: 8),
                                    Text('Đơn giá: $_donGia',
                                        style: TextStyle(fontSize: 18)),
                                    SizedBox(height: 8),
                                    Text('Lần quét: $_lanQuet',
                                        style: TextStyle(fontSize: 18)),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _isButtonLoading
                                          ? null
                                          : _quetThe, // Gọi hàm quét thẻ
                                      child: _isButtonLoading
                                          ? CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            )
                                          : Text('+ 1 Quét thẻ'),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor:
                                            Color(0xFF2d59a4), // Màu nút
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
