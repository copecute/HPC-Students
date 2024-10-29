import 'dart:collection';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';
// Import ThemeProvider
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Import InAppWebView
// Import for defaultTargetPlatform
import 'package:flutter/gestures.dart'; // Import for VerticalDragGestureRecognizer
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
// Import for intl package
import 'package:intl/intl.dart';

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
    _loadTextSize(); // Load cached text size
    _fetchPostDetails(); // Fetch post details on init
  }

  // Load the cached text size from SharedPreferences
  Future<void> _loadTextSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      textSize = prefs.getInt('textSize') ??
          kInitialTextSize; // Default to initial size if not set
    });
  }

  // Save the text size to SharedPreferences
  Future<void> _saveTextSize(int newSize) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('textSize', newSize);
  }

  // Add a method to update the text size and cache it
  void _updateTextSize(int newSize) {
    setState(() {
      textSize = newSize;
    });
    _saveTextSize(textSize); // Save the new text size
    updateTextSize(textSize); // Update the web view text size
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
    // Định dạng lại published date
    String formattedDate = '';
    try {
      // Parse chuỗi ISO 8601 thành DateTime
      DateTime publishedDate = DateTime.parse(published ?? '');
      // Format lại theo định dạng mong muốn
      formattedDate = DateFormat('HH:mm - dd/MM/yyyy').format(publishedDate);
    } catch (e) {
      formattedDate =
          published ?? ''; // Giữ nguyên giá trị gốc nếu parse thất bại
    }

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
            max-width: 100vw; /* Đảm bảo trang không rộng hơn màn hình */
            overflow-x: hidden; /* Không cho phép tràn ngang */
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
            padding: 2px 0;
          }
        * {
        outline:0;
        transition:all .0s ease;
        -webkit-transition:all .0s ease;
        -moz-transition:all .0s ease;
        -o-transition:all .0s ease
        }
        *,:before,:after {
        -webkit-box-sizing:border-box;
        -moz-box-sizing:border-box;
        box-sizing:border-box
        }
        a,abbr,acronym,address,applet,b,big,blockquote,caption,center,cite,code,dd,del,dfn,div,dl,dt,em,fieldset,font,form,h1,h2,h3,h4,h5,h6,html,i,iframe,img,ins,kbd,label,legend,li,object,p,pre,q,s,samp,small,span,strike,strong,sub,sup,table,tbody,td,tfoot,th,thead,tr,tt,u,ul,var {
        padding:0;
        border:0;
        outline:0;
        vertical-align:baseline;
        }
        ins {
        text-decoration:underline
        }
        del {
        text-decoration:line-through
        }
        blockquote {
        background-color: $backgroundColor!important;
        color: $textColor!important;
        }
        dl,ul {
        list-style-position:inside;
        font-weight:700;
        list-style:none
        }
        ul li {
        list-style:none
        }
        caption,th {
        text-align:center
        }

        a,a:visited {
        text-decoration:none;
        font-weight:400
        }
        a {
        color:#0094da
        }
        a:hover {
        color:#0093da
        }
        q:after,q:before {
        content:''
        }
        p {
        margin:0
        }
        abbr,acronym {
        border:0
        }

        </style>
      </head>
      <body>
        <div class="title">$title</div>
        <div class="meta">Nhà xuất bản: HPC Students</div>
        <div class="meta">Ngày đăng: $formattedDate</div>
        <div class="meta">Chuyên mục: $category</div>
        <br />
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
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () =>
                _updateTextSize(textSize + 10), // Increase text size
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () =>
                _updateTextSize(textSize - 10), // Decrease text size
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () =>
                _updateTextSize(kInitialTextSize), // Reset text size
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
                onLoadStart: (controller, url) async {
                  // Open the URL in the external browser
                  if (url != null && url.toString() != widget.postUrl) {
                    controller.stopLoading();
                    await launchUrl(Uri.parse(url
                        .toString())); // Use the launch_url function to open the URL
                    // Prevent the web view from loading the new URL
                  }
                },
              ),
            ),
    );
  }
}
