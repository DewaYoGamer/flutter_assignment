import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import './pages/landing.dart';
import './notifiers.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedThemeNotifier,
      builder: (context, value, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'To Do App',
          themeMode: value ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData.light().copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(),
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              secondary: Colors.grey.shade200,
              surface: Colors.white,
              error: Colors.red,
              onPrimary: Colors.white,
              onSecondary: Colors.grey.shade800,
              onSurface: Colors.grey.shade800,
              onError: Colors.white,
              brightness: Brightness.light,
            )
          ),
          darkTheme: ThemeData.dark().copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(),
            colorScheme: ColorScheme.dark(
              primary: Colors.blue.shade700,
              secondary: Colors.grey.shade800,
              surface: Colors.grey.shade900,
              error: Colors.red,
              onPrimary: Colors.grey.shade100,
              onSecondary: Colors.grey.shade100,
              onSurface: Colors.grey.shade100,
              onError: Colors.grey.shade100,
              brightness: Brightness.dark,
            )
          ),
          home: const Landing(),
        );
      },
    );
  }
}
