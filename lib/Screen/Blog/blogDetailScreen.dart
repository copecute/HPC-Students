import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:provider/provider.dart';
import 'package:hpc_students/include/theme_provider.dart'; // Import ThemeProvider

class BlogDetailScreen extends StatefulWidget {
  final String postUrl;

  BlogDetailScreen({required this.postUrl});

  @override
  _BlogDetailScreenState createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  double _textSize = 16.0; // Default text size

  Future<Map<String, String>> _fetchPostDetails() async {
    try {
      final response = await http.get(Uri.parse(widget.postUrl));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final title = document.findAllElements('title').first.text;
        final published = document.findAllElements('published').first.text;
        final category =
            document.findAllElements('category').first.getAttribute('term') ??
                'Không có';
        final content = document
            .findAllElements('content')
            .first
            .text; // Get the HTML content

        return {
          'title': title,
          'published': published,
          'category': category,
          'content': content,
        };
      } else {
        throw Exception('Không thể tải bài viết.');
      }
    } catch (e) {
      return {
        'content': 'Không thể tải bài viết.',
        'title': '',
        'published': '',
        'category': '',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Get the theme provider

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, String>>(
          future: _fetchPostDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Đang tải...');
            } else if (snapshot.hasError) {
              return Text('Lỗi: ${snapshot.error.toString()}');
            } else {
              final postDetails = snapshot.data;
              return Text(postDetails?['title'] ?? '');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                _textSize += 2; // Increase text size
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                if (_textSize > 10) {
                  _textSize -= 2; // Decrease text size
                }
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _fetchPostDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else {
            final postDetails = snapshot.data;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      postDetails?['title'] ?? '',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ngày đăng: ${postDetails?['published'] ?? ''}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Chuyên mục: ${postDetails?['category'] ?? ''}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    // Wrap HtmlWidget in a Container to avoid layout issues
                    Container(
                      child: HtmlWidget(
                        postDetails?['content'] ?? '',
                        textStyle: TextStyle(
                          color: themeProvider.themeMode == ThemeMode.dark ||
                                  themeProvider.themeMode == ThemeMode.system &&
                                      MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.dark
                              ? Colors.white // White text for dark mode
                              : Colors.black, // Black text for light mode
                          fontSize: _textSize, // Set dynamic text size
                        ),
                        customStylesBuilder: (element) {
                          return {
                            'background': 'transparent',
                            'background-color':
                                'transparent', // Remove background color
                            // 'color': 'white', // Ensure text color is white
                          };
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
