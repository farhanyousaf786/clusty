import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeData> {
  static const String _themeKey = 'theme_mode';
  bool _isDark = true;

  ThemeNotifier() : super(_darkTheme) {
    _loadTheme();
  }

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blue[400],
    scaffoldBackgroundColor: const Color(0xFF000000),
    colorScheme: ColorScheme.dark(
      primary: Colors.blue[400]!,
      secondary: Colors.purple[400]!,
      surface: const Color(0xFF1A1A1A),
      background: const Color(0xFF000000),
    ),
    cardColor: const Color(0xFF1A1A1A),
    dividerColor: Colors.grey[800]!,
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.blue[400]),
      bodyLarge: const TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.grey[400]),
    ),
  );

  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue[600],
    scaffoldBackgroundColor: Colors.grey[100],
    colorScheme: ColorScheme.light(
      primary: Colors.blue[600]!,
      secondary: Colors.purple[600]!,
      surface: Colors.white,
      background: Colors.grey[100]!,
    ),
    cardColor: Colors.white,
    dividerColor: Colors.grey[300],
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.blue[600]),
      bodyLarge: const TextStyle(color: Colors.black87),
      bodyMedium: const TextStyle(color: Colors.black54),
    ),
  );

  bool get isDark => _isDark;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_themeKey) ?? true;
    state = _isDark ? _darkTheme : _lightTheme;
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    state = _isDark ? _darkTheme : _lightTheme;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDark);
  }
}
