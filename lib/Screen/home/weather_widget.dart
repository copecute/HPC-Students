import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:hpc_students/include/config.dart';
import 'package:hpc_students/Screen/settingScreen.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  WeatherWidgetState createState() => WeatherWidgetState();
}

class WeatherWidgetState extends State<WeatherWidget> {
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? forecastData;
  bool isLoading = false;
  String error = '';
  String location = 'ha noi';

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> refresh() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final savedLocation = prefs.getString('weather_location') ?? 'ha noi';

    setState(() {
      location = savedLocation;
    });

    await fetchWeather(savedLocation);
  }

  Future<void> _loadWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_weather');
    final cachedForecast = prefs.getString('cached_forecast');
    final cacheTime = prefs.getInt('weather_cache_time');
    final savedLocation = prefs.getString('weather_location') ?? 'ha noi';

    setState(() {
      location = savedLocation;
    });

    if (cachedData != null && cachedForecast != null && cacheTime != null) {
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
      if (cacheAge < const Duration(hours: 1).inMilliseconds) {
        setState(() {
          weatherData = json.decode(cachedData);
          forecastData = json.decode(cachedForecast);
          isLoading = false;
          error = '';
        });
        return;
      }
    }

    await fetchWeather(savedLocation);
  }

  Future<void> fetchWeather(String city) async {
    try {
      final currentResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&lang=vi&units=metric&appid=$openWeatherMapApiKey'));

      final forecastResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$city&lang=vi&units=metric&appid=$openWeatherMapApiKey'));

      if (currentResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);
        final forecast = json.decode(forecastResponse.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_weather', json.encode(currentData));
        await prefs.setString('cached_forecast', json.encode(forecast));
        await prefs.setInt(
            'weather_cache_time', DateTime.now().millisecondsSinceEpoch);

        if (mounted) {
          setState(() {
            weatherData = currentData;
            forecastData = forecast;
            isLoading = false;
            error = '';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            error = 'Không tìm thấy địa điểm';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Có lỗi xảy ra khi tải dữ liệu thời tiết';
          isLoading = false;
        });
      }
    }
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day) return 'Hôm nay';
    if (date.day == now.day + 1) return 'Ngày mai';

    switch (date.weekday) {
      case 1:
        return 'Thứ hai';
      case 2:
        return 'Thứ ba';
      case 3:
        return 'Thứ tư';
      case 4:
        return 'Thứ năm';
      case 5:
        return 'Thứ sáu';
      case 6:
        return 'Thứ bảy';
      case 7:
        return 'Chủ nhật';
      default:
        return '';
    }
  }

  void showWeeklyWeatherDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dự báo thời tiết'),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingScreen(showLocationDialog: true),
                    ),
                  ).then((_) => refresh());
                },
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (weatherData != null) ...[
                    // Current weather section
                    Text(
                      '${weatherData!['name']}, ${weatherData!['sys']['country']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@2x.png',
                          width: 50,
                          height: 50,
                        ),
                        Text(
                          '${weatherData!['main']['temp'].round()}°C',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${weatherData!['weather'][0]['description']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop, size: 16),
                        Text('${weatherData!['main']['humidity']}%'),
                        SizedBox(width: 16),
                        Icon(Icons.air, size: 16),
                        Text('${weatherData!['wind']['speed']} km/h'),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nhiệt độ cao/thấp: ${weatherData!['main']['temp_max'].round()}°/${weatherData!['main']['temp_min'].round()}°',
                      style: TextStyle(fontSize: 14),
                    ),
                    Divider(height: 32),

                    if (forecastData != null) ...[
                      Text(
                        'Dự báo 5 ngày tới',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...List.generate(
                        5,
                        (index) {
                          final forecast = forecastData!['list'][index * 8];
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              forecast['dt'] * 1000);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_getDayName(date)}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Row(
                                  children: [
                                    Image.network(
                                      'https://openweathermap.org/img/wn/${forecast['weather'][0]['icon']}.png',
                                      width: 30,
                                      height: 30,
                                    ),
                                    Text(
                                      '${forecast['main']['temp'].round()}°',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        showWeeklyWeatherDialog();
      },
      child: Container(
        width: double.infinity,
        child: Card(
          margin: EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  Container(
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? Colors.white70 : Colors.blue,
                        ),
                      ),
                    ),
                  )
                else if (error.isNotEmpty)
                  Text(
                    error,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  )
                else if (weatherData != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${weatherData!['name']}, ${weatherData!['sys']['country']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${weatherData!['weather'][0]['description']}',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Image.network(
                                    'https://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}.png',
                                    width: 35,
                                    height: 35,
                                  ),
                                  Text(
                                    '${weatherData!['main']['temp'].round()}°',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.water_drop,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${weatherData!['main']['humidity']}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    Icons.air,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${weatherData!['wind']['speed']} km/h',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                if (!isLoading && error.isEmpty && weatherData != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'thời tiết hôm nay rất đẹp để đi học',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
