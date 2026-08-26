import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    useMaterial3: true,
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    useMaterial3: true,
  );

  void toggleTheme() {
    // Enhancement 3: Notify MaterialApp so the selected settings-page theme
    // is applied immediately to every screen in the application.
    _isDark = !_isDark;
    notifyListeners();
  }
}
