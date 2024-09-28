import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class BlogDetailScreen extends StatelessWidget {
  final String postUrl;

  BlogDetailScreen({required this.postUrl});

  Future<Map<String, String>> _fetchPostDetails() async {
    try {
      final response = await http.get(Uri.parse(postUrl));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final title = document.findAllElements('title').first.text;
        final published = document.findAllElements('published').first.text;
        final category = document.findAllElements('category').first.getAttribute('term') ?? 'Không có';
        final author = document.findAllElements('author').first.findElements('name').first.text;

        return {
          'title': title,
          'published': published,
          'category': category,
          'author': author,
          'content': document.findAllElements('content').first.text,
        };
      } else {
        throw Exception('Failed to load post details');
      }
    } catch (e) {
      return {
        'content': 'Không thể tải bài viết.',
        'title': '',
        'published': '',
        'category': '',
        'author': '',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nội dung bài viết'),
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                    Text(
                      'Tác giả: ${postDetails?['author'] ?? ''}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    Text(postDetails?['content'] ?? ''),
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
