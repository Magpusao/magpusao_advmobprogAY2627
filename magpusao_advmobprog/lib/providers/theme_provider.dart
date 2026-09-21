import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeProvider with ChangeNotifier {
  static const avocadoSmoothie = Color(0xFFC2C395);
  static const blushBeet = Color(0xFFDDBAAE);
  static const peachProtein = Color(0xFFEFD7CF);
  static const oatLatte = Color(0xFFDCD4C1);
  static const honeyOatmilk = Color(0xFFF6EAD4);
  static const coconutCream = Color(0xFFFFFAF2);

  static const _ink = Color(0xFF454238);
  static const _mutedInk = Color(0xFF686257);
  static const _darkBackground = Color(0xFF28271F);
  static const _darkSurface = Color(0xFF343227);

  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: avocadoSmoothie,
          brightness: Brightness.light,
        ).copyWith(
          primary: avocadoSmoothie,
          onPrimary: _ink,
          primaryContainer: oatLatte,
          onPrimaryContainer: _ink,
          secondary: blushBeet,
          onSecondary: _ink,
          secondaryContainer: peachProtein,
          onSecondaryContainer: _ink,
          tertiary: peachProtein,
          onTertiary: _ink,
          tertiaryContainer: honeyOatmilk,
          onTertiaryContainer: _ink,
          surface: coconutCream,
          onSurface: _ink,
          onSurfaceVariant: _mutedInk,
          outline: avocadoSmoothie,
          outlineVariant: oatLatte,
          surfaceContainerHighest: oatLatte,
        );

    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: honeyOatmilk,
      appBarTheme: const AppBarTheme(
        backgroundColor: avocadoSmoothie,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(color: coconutCream),
      cardTheme: const CardThemeData(color: coconutCream, elevation: 0),
    );
  }

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: avocadoSmoothie,
      brightness: Brightness.dark,
      primary: avocadoSmoothie,
      secondary: blushBeet,
      tertiary: peachProtein,
      surface: _darkSurface,
    ),
    scaffoldBackgroundColor: _darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: avocadoSmoothie,
      foregroundColor: _ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(color: _darkSurface),
    cardTheme: const CardThemeData(color: _darkSurface, elevation: 0),
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
