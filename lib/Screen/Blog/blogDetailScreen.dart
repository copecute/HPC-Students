import 'dart:collection';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:provider/provider.dart';
import 'package:hpc_students/include/theme_provider.dart'; // Import ThemeProvider
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Import InAppWebView
import 'package:flutter/services.dart'; // Import for defaultTargetPlatform
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

        setState(() {}); // Update the UI
      } else {
        throw Exception('Không thể tải bài viết.');
      }
    } catch (e) {
      setState(() {
        htmlContent = '<h1>Không thể tải bài viết.</h1>'; // Fallback HTML
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
          }
          img {
            max-width: 100%;
            height: auto;
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
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () async {
              await updateTextSize(textSize + 10); // Increase text size
            },
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () async {
              await updateTextSize(textSize - 10); // Decrease text size
            },
          ),
          TextButton(
            onPressed: () async {
              await updateTextSize(kInitialTextSize); // Reset text size
            },
            child: const Text(
              'Đặt lại',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: htmlContent == null
          ? Center(child: CircularProgressIndicator())
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
              ),
            ),
    );
  }
}
