import 'package:flutter/material.dart';

const Color kCyan = Color(0xFF00E5FF);
const Color kBlue = Color(0xFF1E90FF);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kBlue,
    brightness: Brightness.dark,
  ).copyWith(primary: kCyan, secondary: kBlue, surface: Colors.black);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
