import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login_page.dart';
import 'pages/landing.dart';
import './notifiers.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
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
          title: 'Anggota App',
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
            ),
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
            ),
          ),
          home: const AuthCheckPage(),
        );
      },
    );
  }
}

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (isLoggedIn) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LandingPage()));
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : const Text('Checking authentication...'),
      ),
    );
  }
}
