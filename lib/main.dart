import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stylecv/public/views/home_secreen.dart';

import 'package:stylecv/public/views/login_screen.dart';
import 'package:stylecv/public/views/signup_screen.dart';

import 'db/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );  // Firebase başlatılıyor
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StyliCV',
      theme: ThemeData(
        primaryColor: const Color(0xff142831),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xff1a936f),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}
