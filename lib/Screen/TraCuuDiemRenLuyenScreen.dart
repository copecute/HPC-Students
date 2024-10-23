import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:html/parser.dart' as htmlParser;
import 'package:provider/provider.dart';
import '../include/cookie_provider.dart';
import '../include/config.dart';
import 'loginScreen.dart';
import 'package:fl_chart/fl_chart.dart';

class TraCuuDiemRenLuyenScreen extends StatefulWidget {
  @override
  _TraCuuDiemRenLuyenScreenState createState() =>
      _TraCuuDiemRenLuyenScreenState();
}

class _TraCuuDiemRenLuyenScreenState extends State<TraCuuDiemRenLuyenScreen> {
  List<Map<String, dynamic>>? diemRenLuyenData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    String? cookie =
        Provider.of<CookieProvider>(context, listen: false).getCookie();

    if (cookie == null || cookie.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LoginScreen()), // Redirect to login if no cookie
      );
      return;
    }

    final url = '$baseUrl/TraCuuDiem/DiemRenLuyen';
    final HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    final ioClient = IOClient(httpClient);

    try {
      final response = await ioClient.get(
        Uri.parse(url),
        headers: {
          'Cookie': cookie, // Send cookie for authentication
        },
      );

      if (response.statusCode == 200) {
        var document = htmlParser.parse(response.body);
        var table = document.querySelector("table.table-bordered");

        if (table != null) {
          var yearHeaderRows = table.querySelectorAll('tr:first-child td');
          var dataRow = table.querySelector('tr[style="color:#ff0000"]');

          if (dataRow != null) {
            var dataCells = dataRow.querySelectorAll('td');
            var data = <Map<String, dynamic>>[];

            int? startYear;
            var firstYearHeader = yearHeaderRows[0]
                .querySelector('table tbody tr:first-child td');
            if (firstYearHeader != null) {
              var match =
                  RegExp(r'(\d{4})-(\d{4})').firstMatch(firstYearHeader.text);
              if (match != null) {
                startYear = int.parse(match.group(1)!);
              }
            }

            for (int i = 0; i < dataCells.length - 2; i++) {
              var yearData = dataCells[i].querySelector('table');
              if (yearData != null) {
                if (i != 0 && startYear != null) {
                  startYear = startYear + 1;
                }
                String yearHeader = startYear != null
                    ? 'Năm học $startYear-${startYear + 1}'
                    : 'Năm học';

                var cells = yearData.querySelectorAll('tbody tr td');
                if (cells.length >= 4) {
                  data.add({
                    'year': yearHeader,
                    'term1': cells[0].text.trim(),
                    'term2': cells[1].text.trim(),
                    'total': cells[2].text.trim(),
                    'grade': cells[3].text.trim(),
                  });
                }
              }
            }

            // Add Tổng khóa data
            if (dataCells.length >= 2) {
              data.add({
                'year': "Tổng khóa",
                'total': dataCells[dataCells.length - 2].text.trim(),
                'grade': dataCells[dataCells.length - 1].text.trim(),
              });
            }

            setState(() {
              diemRenLuyenData = data;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      ioClient.close();
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchData();
  }

  List<FlSpot> _getChartData() {
    List<FlSpot> spots = [];
    if (diemRenLuyenData != null) {
      for (int i = 0; i < diemRenLuyenData!.length - 1; i++) {
        // Exclude "Tổng khóa"
        var data = diemRenLuyenData![i];
        double total = double.tryParse(data['total']) ?? 0;
        spots.add(FlSpot(i.toDouble(), total));
      }
    }
    return spots;
  }

  Widget _buildChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.only(left: 0, right: 50, top: 20, bottom: 0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < diemRenLuyenData!.length - 1) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 10,
                      child: Text(
                        diemRenLuyenData![index]['year'].split(' ')[2],
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(''),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 5,
                    child: Text(
                      value.toInt().toString(),
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  );
                },
                reservedSize: 45,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          minX: 0,
          maxX: (diemRenLuyenData!.length - 2).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: _getChartData(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Điểm Rèn Luyện'),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : diemRenLuyenData == null || diemRenLuyenData!.isEmpty
                ? Center(child: Text('Không có dữ liệu'))
                : ListView(
                    children: [
                      _buildChart(),
                      ...diemRenLuyenData!.map((data) => Card(
                            margin: EdgeInsets.all(8),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['year'],
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 12),
                                  if (data['year'] != "Tổng khóa")
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Kỳ 1: ${data['term1']}',
                                                style: TextStyle(fontSize: 16)),
                                            SizedBox(height: 4),
                                            Text('Kỳ 2: ${data['term2']}',
                                                style: TextStyle(fontSize: 16)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text('Tổng: ${data['total']}',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            SizedBox(height: 4),
                                            Text('Xếp loại: ${data['grade']}',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Tổng: ${data['total']}',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        Text('Xếp loại: ${data['grade']}',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ))
                    ],
                  ),
      ),
    );
  }
}
