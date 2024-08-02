
import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xff009218),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xff009218),
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  fontFamily: "poppins_regular"
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xff009218),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xff009218),
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  fontFamily: "poppins_regular",


);

class ThemeProvider extends ChangeNotifier {
  bool isDarkMode = false;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
