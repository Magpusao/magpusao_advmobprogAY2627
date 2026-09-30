import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeProvider with ChangeNotifier {
  static const brandIndigo = Color(0xFF3F51B5);
  static const brandAmber = Color(0xFFFFBE24);
  static const lightBackground = Color(0xFFF8F5FC);
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);

  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandIndigo,
      primary: brandIndigo,
      secondary: brandAmber,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: brandIndigo,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandIndigo,
      brightness: Brightness.dark,
      primary: const Color(0xFFAAB4FF),
      secondary: brandAmber,
      surface: darkSurface,
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: brandIndigo,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
  );

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    if (_isDark == isDark) return;
    _isDark = isDark;
    notifyListeners();
  }
}
