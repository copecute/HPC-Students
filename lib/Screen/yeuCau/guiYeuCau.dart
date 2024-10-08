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
              url: WebUri.uri(Uri.parse('$baseUrl/DangNhap/Logout')),
              headers: {
                'Cookie': widget.cookie, // Include the cookie in the request
              },
            ),
            onWebViewCreated: (InAppWebViewController controller) {
              // You can store the controller if needed
            },
            onLoadStart: (controller, url) async {
              print("Loading: $url");
              setState(() {
                _isLoading = true; // Set loading to true when loading starts
              });

              // Determine the background color based on the theme
              String backgroundColor;
              String textColor;
              if (Theme.of(context).brightness == Brightness.dark ||
                  Theme.of(context).brightness == Brightness.light) {
                backgroundColor = '#252833';
                textColor = 'white';
              } else {
                backgroundColor =
                    Theme.of(context).scaffoldBackgroundColor.toString();
                textColor = 'black'; // Default text color for light theme
              }

              // Inject CSS to hide specific elements before the content loads
              await controller.evaluateJavascript(source: '''
                const style = document.createElement('style');
                style.innerHTML = `
                  body {
                    background: $backgroundColor;
                    color: $textColor;
                    width: 100%;
                    overflow-x: hidden;
                  }
                  .news-listing {
                    background: $backgroundColor;
                    color: $textColor;
                    }
                  section[style="background:#ffffff"] {
                    display: none !important;
                  }
                  header[style="background-color:#3b5998"] {
                    display: none !important;
                  }
                  div.footer {
                    display: none !important;
                  }
                  ol#breadcumb {
                    display: none !important;
                  }
                  img {
                  width: 100%;
                  }
                `;
                document.head.appendChild(style);
              ''');
            },
            onLoadStop: (controller, url) async {
              if (url != null) {
                print("Loaded: $url");

                // Check if the URL is the home page after logout
                if (url.toString() == '$baseUrl/') {
                  // Redirect to the login page
                  await controller.loadUrl(
                      urlRequest: URLRequest(
                          url: WebUri.uri(
                              Uri.parse('$baseUrl/DangNhap/Login'))));
                  return; // Exit the method to prevent further processing
                }

                // Check if the URL is the login page
                if (url.toString() == '$baseUrl/DangNhap/Login') {
                  // Inject JavaScript to fill in the username and password and submit the form
                  await controller.evaluateJavascript(source: '''
                    document.getElementById('UserName').value = '$username';
                    document.getElementById('Password').value = '$password';
                    document.querySelector('button[type="submit"]').click();
                  ''');
                }

                // Check if the URL is the post-login page
                if (url.toString() == '$baseUrl/SinhVien') {
                  // After successful login, navigate to the desired page
                  await controller.loadUrl(
                      urlRequest: URLRequest(
                          url: WebUri.uri(
                              Uri.parse('$baseUrl/ThongBao/Index'))));
                }

                // Inject JavaScript to remove specified elements, click the link, add CSS, and display the name
                await controller.evaluateJavascript(source: '''
                  // Extract the name from the specified div within ulMenu2
                  const nameDiv = document.querySelector('#ulMenu2 .styMenu');
                  let nameText = 'Ẩn danh'; // Default name
                  if (nameDiv) {
                    nameText = nameDiv.childNodes[0].textContent.trim();
                  }
                  // Create a new div to display the name
                  const newDiv = document.createElement('div');
                  newDiv.style.border = '1px solid #2652a0';
                  newDiv.style.borderRadius = '20px';
                  newDiv.style.marginBottom = '10px';
                  newDiv.style.color = '#2652a0';
                  newDiv.style.fontWeight = 'bold';
                  newDiv.style.fontSize = '15px';
                  newDiv.style.padding = '5px 10px 5px 25px';
                  newDiv.className = 'col-md-6 col-md-offset-3 hover';

                  // Create the icon span
                  const iconSpan = document.createElement('span');
                  iconSpan.className = 'glyphicon glyphicon-user';
                  iconSpan.style.padding = '5px';

                  // Append the icon and name to the new div
                  newDiv.appendChild(iconSpan);
                  newDiv.appendChild(document.createTextNode('Người gửi: ' + nameText));
                  
                  // Insert the new div after the specified div
                  const targetDiv = document.querySelector('.col-md-3 .row');
                  if (targetDiv) {
                    targetDiv.insertAdjacentElement('afterend', newDiv);
                  }
                  
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

                // Delay for 1 second before setting loading to false
                await Future.delayed(Duration(seconds: 1));
                setState(() {
                  _isLoading = false; // Set loading to false after delay
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
