import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:provider/provider.dart';
import 'package:hpc_students/include/cookie_provider.dart'; // Import CookieProvider
import 'package:hpc_students/include/config.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart'; // Import HtmlWidget

class ChiTietYeuCauScreen extends StatefulWidget {
  final String id;
  final String gui;
  final String page;
  final String hopthu;

  ChiTietYeuCauScreen({
    required this.id,
    required this.gui,
    required this.page,
    required this.hopthu,
  });

  @override
  _ChiTietYeuCauScreenState createState() => _ChiTietYeuCauScreenState();
}

class _ChiTietYeuCauScreenState extends State<ChiTietYeuCauScreen> {
  String? _htmlContent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetailData(); // Fetch the detail data on initialization
  }

  Future<void> _fetchDetailData() async {
    final String? cookie = Provider.of<CookieProvider>(context, listen: false)
        .getCookie(); // Get cookie
    final url =
        '$baseUrl/ThongBao/ChiTietHopThuDen?ID=${widget.id}&Gui=${widget.gui}&Page=${widget.page}&hopthu=${widget.hopthu}';

    final ioClient = IOClient();

    try {
      final response = await ioClient.get(
        Uri.parse(url),
        headers: {
          'Cookie': cookie ?? '', // Include cookie in the request
        },
      );
      print(url);
      print(response.body);
      if (response.statusCode == 200) {
        // Combine the modifications into a single variable
        String modifiedHtmlContent = response.body
            .replaceAll('src="/FileManager/Upload/images/',
                'src="$baseUrl/FileManager/Upload/images/')
            .replaceAll(
                'class="col-md-12" style="border-bottom:1px solid #067bd0"',
                'class="col-md-12" style="display: none;"')
            .replaceAll(
                'class="btn btn-control" style="font-weight:bold;font-size:13px;color:#001da7;border-bottom:3px solid #d2dde1;margin-left:-15px;"',
                'class="btn btn-control" style="display: block;text-align: center;font-weight:bold;font-size: 30px;color: unset;"')
            .replaceAll('style="color:#808080;float:right"',
                'style="display: block;text-align: center;"')
            .replaceAll(
                '<div id="divNoiDung" class="col-md-12" style="margin-top:6px;border:1px solid #051ca7;border-radius:10px;padding:20px;min-height:150px"',
                '<div id="divNoiDung" class="col-md-12" style="margin-top:6px;border:3px solid #2957a4;border-radius:10px;padding:20px;min-height:150px"' // Updated style
                );

        setState(() {
          _htmlContent = modifiedHtmlContent; // Store the HTML content
          _isLoading = false; // Set loading to false
        });
      } else {
        // Handle error response
        setState(() {
          _isLoading = false; // Set loading to false
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false; // Set loading to false
      });
    } finally {
      ioClient.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi Tiết Yêu Cầu'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _htmlContent != null
              ? SingleChildScrollView(
                  child: HtmlWidget(_htmlContent!), // Display the HTML content
                )
              : Center(
                  child: Text('Yêu cầu không tồn tại')), // Handle no data case
    );
  }
}
