import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String THEME_KEY = 'theme_mode';

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;

  // Load theme from SharedPreferences when app starts
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(THEME_KEY);
    if (savedThemeMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedThemeMode,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  // Save theme to SharedPreferences when it changes
  Future<void> toggleTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(THEME_KEY, mode.toString());

    print('Theme changed to: ${mode.toString()}'); // Print the current theme
  }

  // Define the dark theme
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF16253f), // Primary color for dark theme
      scaffoldBackgroundColor: Color(0xFF282a36), // Background color
      appBarTheme: AppBarTheme(
        // backgroundColor: Color(0xFF16253f), // AppBar color
        iconTheme: IconThemeData(color: Colors.white), // Icon color in AppBar
        titleTextStyle:
            TextStyle(color: Colors.white, fontSize: 20), // Title text style
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white), // Body text color
        bodyMedium: TextStyle(color: Colors.white70), // Secondary text color
        displayLarge: TextStyle(color: Colors.white), // Headline text color
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800], // Input field background color
        labelStyle: TextStyle(color: Colors.white), // Label color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white), // Border color
        ),
      ),
      iconTheme: IconThemeData(color: Colors.white), // Icon color
    );
  }

  // Define the light theme
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xFF2d59a4), // Primary color for light theme
      scaffoldBackgroundColor: Colors.white, // Background color
      appBarTheme: AppBarTheme(
        // backgroundColor: Color(0xFF2d59a4), // AppBar color
        iconTheme: IconThemeData(color: Colors.black), // Icon color in AppBar
        titleTextStyle:
            TextStyle(color: Colors.black, fontSize: 20), // Title text style
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.black), // Body text color
        bodyMedium: TextStyle(color: Colors.black54), // Secondary text color
        displayLarge: TextStyle(color: Colors.black), // Headline text color
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white, // Input field background color
        labelStyle: TextStyle(color: Colors.black), // Label color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black), // Border color
        ),
      ),
      iconTheme: IconThemeData(color: Colors.black), // Icon color
    );
  }
}
