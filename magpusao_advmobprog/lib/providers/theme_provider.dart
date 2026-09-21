import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeProvider with ChangeNotifier {
  static const _brandIndigo = Color(0xFF3F51B5);
  static const _brandAmber = Color(0xFFFFBE24);
  static const _lightBackground = Color(0xFFF8F5FC);
  static const _darkBackground = Color(0xFF121212);
  static const _darkSurface = Color(0xFF1E1E1E);

  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _brandIndigo,
      primary: _brandIndigo,
      secondary: _brandAmber,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: _lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: _brandIndigo,
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
      seedColor: _brandIndigo,
      brightness: Brightness.dark,
      primary: const Color(0xFFAAB4FF),
      secondary: _brandAmber,
      surface: _darkSurface,
    ),
    scaffoldBackgroundColor: _darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: _brandIndigo,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
  );

  void toggleTheme() {
    // Enhancement 3: Notify MaterialApp so the selected settings-page theme
    // is applied immediately to every screen in the application.
    _isDark = !_isDark;
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    if (_isDark == isDark) return;
    _isDark = isDark;
    notifyListeners();
  }
}
