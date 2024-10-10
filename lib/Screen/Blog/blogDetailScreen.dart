import 'dart:collection';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
// Import ThemeProvider
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Import InAppWebView
// Import for defaultTargetPlatform
import 'package:flutter/gestures.dart'; // Import for VerticalDragGestureRecognizer

const kInitialTextSize = 100; // Initial text size percentage
const kTextSizePlaceholder = 'TEXT_SIZE_PLACEHOLDER';
const kTextSizeSourceJS = """
window.addEventListener('DOMContentLoaded', function(event) {
  document.body.style.textSizeAdjust = '$kTextSizePlaceholder%';
  document.body.style.webkitTextSizeAdjust = '$kTextSizePlaceholder%';
});
""";

final textSizeUserScript = UserScript(
    source:
        kTextSizeSourceJS.replaceAll(kTextSizePlaceholder, '$kInitialTextSize'),
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START);

class BlogDetailScreen extends StatefulWidget {
  final String postUrl;

  BlogDetailScreen({required this.postUrl});

  @override
  _BlogDetailScreenState createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  late InAppWebViewController webViewController;
  String? htmlContent;
  String? title;
  String? published;
  String? category;
  int textSize = kInitialTextSize; // Current text size
  bool _isLoading = true; // Loading state

  Future<void> _fetchPostDetails() async {
    try {
      final response = await http.get(Uri.parse(widget.postUrl));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        title = document.findAllElements('title').first.text;
        published = document.findAllElements('published').first.text;
        category =
            document.findAllElements('category').first.getAttribute('term') ??
                'Không có';
        htmlContent = document
            .findAllElements('content')
            .first
            .text; // Get the HTML content

        setState(() {
          _isLoading = false; // Set loading to false after fetching
        }); // Update the UI
      } else {
        throw Exception('Không thể tải bài viết.');
      }
    } catch (e) {
      setState(() {
        htmlContent = '<h1>Không thể tải bài viết.</h1>'; // Fallback HTML
        _isLoading = false; // Set loading to false on error
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPostDetails(); // Fetch post details on init
  }

  Future<void> updateTextSize(int newSize) async {
    textSize = newSize;

    if (textSize < 10) textSize = 10; // Minimum text size
    if (textSize > 200) textSize = 200; // Maximum text size

    // Update text size for Android
    await webViewController.setSettings(
      settings: InAppWebViewSettings(textZoom: textSize),
    );

    // Update text size for iOS using JavaScript
    await webViewController.evaluateJavascript(source: """
      document.body.style.textSizeAdjust = '${textSize}%';
      document.body.style.webkitTextSizeAdjust = '${textSize}%';
    """);

    // Update the User Script for the next page load
    await webViewController.removeUserScript(userScript: textSizeUserScript);
    textSizeUserScript.source =
        kTextSizeSourceJS.replaceAll(kTextSizePlaceholder, '$textSize');
    await webViewController.addUserScript(userScript: textSizeUserScript);
  }

  String _getHtmlWithTheme(String content) {
    // Determine the current theme
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    // Inject CSS for background color based on the theme
    final backgroundColor =
        isDarkTheme ? '#252833' : '#FFFFFF'; // Dark or light background
    final textColor = isDarkTheme ? '#FFFFFF' : '#000000'; // Text color

    return """
    <html>
      <head>
      <meta content='text/html; charset=UTF-8' http-equiv='Content-Type'/>
      <meta content='width=device-width, initial-scale=1' name='viewport'/>
        <style>
          body {
            background-color: $backgroundColor;
            color: $textColor;
            font-size: ${textSize}%;
            max-width: 100%;
            overflow-x: hidden;
            font-family: 'Times New Roman', Times, serif;
          }
          img {
            max-width: 100%;
            height: auto;
            display: block;
            margin-left: auto;
            margin-right: auto;
          }
          .title {
            font-size: 24px;
            font-weight: bold;
          }
          .meta {
            color: grey;
          }
        </style>
      </head>
      <body>
        <div class="title">$title</div>
        <div class="meta">Ngày đăng: $published</div>
        <div class="meta">Chuyên mục: $category</div>
        <div>$content</div>

               <link href='https://cdn.jsdelivr.net/gh/fancyapps/fancybox@3.5.7/dist/jquery.fancybox.min.css' rel='stylesheet'/>
        <script src='https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js'></script>
        <script src='https://cdn.jsdelivr.net/gh/fancyapps/fancybox@3.5.7/dist/jquery.fancybox.min.js'></script>
        <script>
document.addEventListener("DOMContentLoaded", function() {
  var images = document.querySelectorAll('img');
  images.forEach(function(img) {
    var img_link = img.getAttribute('src');
    
    // Tạo thẻ a để bọc img
    var anchor = document.createElement('a');
    anchor.setAttribute('href', img_link);
    anchor.setAttribute('data-fancybox', 'gallery');
  
    // Chèn thẻ a vào trước img và bọc img bên trong a
    img.parentNode.insertBefore(anchor, img);
    anchor.appendChild(img);
  });

  // Lấy tất cả các thẻ .tr-caption-container
  var captionContainers = document.querySelectorAll('.tr-caption-container');
  captionContainers.forEach(function(container) {
    var caption = container.querySelector('.tr-caption').textContent;
    var anchor = container.querySelector('a');
    
    // Thêm data-caption vào thẻ a
    if (anchor) {
      anchor.setAttribute('data-caption', caption);
    }
  });
});

        </script>
      </body>
    </html>
    """;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('${category?.isNotEmpty == true ? category : 'Đang tải...'}'),
        actions: [
          PopupMenuButton<int>(
            icon: Icon(Icons.zoom_in),
            onSelected: (value) {
              if (value == 1) {
                updateTextSize(textSize + 10); // Increase text size
              } else if (value == 2) {
                updateTextSize(textSize - 10); // Decrease text size
              } else if (value == 3) {
                updateTextSize(kInitialTextSize); // Reset text size
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 1, child: Text('Phóng to')),
              PopupMenuItem(value: 2, child: Text('Thu nhỏ')),
              PopupMenuItem(value: 3, child: Text('Đặt lại')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : Container(
              width: double.infinity,
              height: double.infinity, // Full screen height
              child: InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: _getHtmlWithTheme(
                      htmlContent!), // Inject theme-based HTML
                  mimeType: "text/html",
                  encoding: "utf-8",
                  baseUrl: WebUri(widget.postUrl), // Convert to WebUri
                ),
                // Allow vertical scrolling within the web view
                gestureRecognizers: Set()
                  ..add(Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer())),
                initialUserScripts: UnmodifiableListView(
                    !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                        ? []
                        : [textSizeUserScript]),
                onWebViewCreated: (InAppWebViewController controller) {
                  webViewController = controller;
                  updateTextSize(textSize); // Set initial zoom
                },
                onLoadError: (controller, url, code, message) {
                  print("Error loading: $message");
                },
                onLoadHttpError: (controller, url, code, message) {
                  print("HTTP Error: $message");
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    htmlContent =
                        htmlContent; // Cập nhật lại htmlContent để tắt loading
                  });
                },
              ),
            ),
    );
  }
}
