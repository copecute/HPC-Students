import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hpc_students/include/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppWebViewScreen extends StatefulWidget {
  final String cookie;

  InAppWebViewScreen({required this.cookie});

  @override
  _InAppWebViewScreenState createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  bool _isLoading = true; // Track loading state
  String? username;
  String? password;

  @override
  void initState() {
    super.initState();
    _loadCredentials(); // Load credentials when the state is initialized
  }

  Future<void> _loadCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
      password = prefs.getString('password');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gửi Yêu Cầu'),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri.uri(Uri.parse(
                  'https://sinhvien.bachkhoahanoi.edu.vn/DangNhap/Logout')),
              headers: {
                'Cookie': widget.cookie, // Include the cookie in the request
              },
            ),
            onWebViewCreated: (InAppWebViewController controller) {
              // You can store the controller if needed
            },
            onLoadStart: (controller, url) {
              print("Loading: $url");
              setState(() {
                _isLoading = true; // Set loading to true when loading starts
              });
            },
            onLoadStop: (controller, url) async {
              if (url != null) {
                print("Loaded: $url");

                // Check if the URL is the home page after logout
                if (url.toString() ==
                    'https://sinhvien.bachkhoahanoi.edu.vn/') {
                  // Redirect to the login page
                  await controller.loadUrl(
                      urlRequest: URLRequest(
                          url: WebUri.uri(Uri.parse(
                              'https://sinhvien.bachkhoahanoi.edu.vn/DangNhap/Login'))));
                  return; // Exit the method to prevent further processing
                }

                // Check if the URL is the login page
                if (url.toString() ==
                    'https://sinhvien.bachkhoahanoi.edu.vn/DangNhap/Login') {
                  // Inject JavaScript to fill in the username and password and submit the form
                  await controller.evaluateJavascript(source: '''
                    document.getElementById('UserName').value = '$username';
                    document.getElementById('Password').value = '$password';
                    document.querySelector('button[type="submit"]').click();
                  ''');
                }

                // Check if the URL is the post-login page
                if (url.toString() ==
                    'https://sinhvien.bachkhoahanoi.edu.vn/SinhVien') {
                  // After successful login, navigate to the desired page
                  await controller.loadUrl(
                      urlRequest: URLRequest(
                          url: WebUri.uri(
                              Uri.parse('$baseUrl/ThongBao/Index'))));
                }

                // Determine the background color based on the theme
                String backgroundColor;
                String textColor;
                if (Theme.of(context).brightness == Brightness.dark ||
                    Theme.of(context).brightness == Brightness.light) {
                  backgroundColor = '#16253f';
                  textColor = 'white';
                } else {
                  backgroundColor =
                      Theme.of(context).scaffoldBackgroundColor.toString();
                  textColor = 'black'; // Default text color for light theme
                }

                // Inject CSS to set the background color and text color
                await controller.evaluateJavascript(source: '''
                  document.body.style.backgroundColor = '$backgroundColor';
                  document.body.style.color = '$textColor';
                  const style = document.createElement('style');
                  style.innerHTML = `
                    .news-listing {
                      background: $backgroundColor;
                      color: $textColor;
                    }
                  `;
                  document.head.appendChild(style);
                ''');

                // Inject JavaScript to remove specified elements, click the link, add CSS, and display the name
                await controller.evaluateJavascript(source: '''
                  // Extract the name from the specified div within ulMenu2
                  const nameDiv = document.querySelector('#ulMenu2 .styMenu');
                  if (nameDiv) {
                    const nameText = nameDiv.childNodes[0].textContent.trim();
                    // Create a new div to display the name
                    const newDiv = document.createElement('div');
                    newDiv.textContent = nameText;
                    newDiv.style.textAlign = 'center'; // Center align the text
                    newDiv.style.marginTop = '10px'; // Add some margin
                    // Insert the new div below the target div
                    const targetDiv = document.querySelector('.col-md-12.fullwidth');
                    if (targetDiv) {
                      targetDiv.insertAdjacentElement('afterend', newDiv);
                    }
                  }
                  
                  document.querySelector('section[style="background:#ffffff"]').remove();
                  document.querySelector('header[style="background-color:#3b5998"]').remove();
                  document.querySelector('div.footer').remove();
                  document.querySelector('ol#breadcumb').remove();
                  
                  // Automatically click the link if it exists
                  const link = document.querySelector('a[onclick="SoanTinNhanClick()"]');
                  if (link) {
                    link.click();
                  }

                  // Add CSS to set img width to 100%
                  const imgStyle = document.createElement('style');
                  imgStyle.innerHTML = 'img { width: 100%; }';
                  document.head.appendChild(imgStyle);
                ''');

                // Set loading to false after JavaScript evaluation is complete
                setState(() {
                  _isLoading = false; // Set loading to false when loading stops
                });
              }
            },
            // Handle SSL errors
            onReceivedServerTrustAuthRequest: (controller, request) async {
              // Accept all SSL certificates
              return ServerTrustAuthResponse(
                  action: ServerTrustAuthResponseAction.PROCEED);
            },
          ),
          if (_isLoading) // Show loading indicator if loading
            Container(
              color: Theme.of(context)
                  .colorScheme
                  .background
                  .withOpacity(1), // Background color based on theme
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
