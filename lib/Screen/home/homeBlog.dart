import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

class HomeBlog {
  String blogID;
  List<Map<String, String>> blogPosts = [];
  bool hasFetchedData = false;

  HomeBlog(this.blogID);

  Future<void> fetchBlogPosts() async {
    if (hasFetchedData)
      return; // Prevent fetching if data has already been fetched

    String url =
        'https://www.blogger.com/feeds/$blogID/posts/default?max-results=5';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Parse the XML response
        final document = XmlDocument.parse(response.body);
        final entries = document.findAllElements('entry');

        List<Map<String, String>> tempPosts = [];
        for (var entry in entries) {
          final title = entry.findElements('title').single.text;
          final published = entry.findElements('published').single.text;
          final category = entry
              .findElements('category')
              .firstWhere(
                (link) =>
                    link.getAttribute('scheme') ==
                    'http://www.blogger.com/atom/ns#',
                orElse: () => XmlElement(XmlName('category')),
              )
              .getAttribute('term');

          final selfLink = entry
              .findElements('link')
              .firstWhere(
                (link) => link.getAttribute('rel') == 'self',
                orElse: () => XmlElement(XmlName('link')),
              )
              .getAttribute('href');

          // Use the new _getThumbnail method to extract the image URL
          final imageUrl = getThumbnail(entry);

          // Ensure selfLink is not null before adding it to the post data
          if (selfLink != null) {
            tempPosts.add({
              'title': title,
              'published': published,
              'category': category ?? "Mới",
              'self': selfLink,
              'image': imageUrl ??
                  'default_image_url', // Replace with actual default image URL
            });
          }
        }

        // Cache the fetched blog posts in JSON format
        await cacheBlogPosts(tempPosts);

        blogPosts = tempPosts; // Update the blog posts list
        hasFetchedData = true; // Set the flag to true after fetching
      } else {
        throw Exception('Failed to fetch blog posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching blog posts: $e');
    }
  }

  Future<void> cacheBlogPosts(List<Map<String, String>> posts) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedPosts = json.encode(posts);
    await prefs.setString('cachedBlogPosts', encodedPosts);
  }

  String? getThumbnail(XmlElement post) {
    // Implement your thumbnail extraction logic here
    return null; // Placeholder
  }
}
