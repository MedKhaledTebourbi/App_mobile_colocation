import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion User UI',
      debugShowCheckedModeBanner: false, // enlève le bandeau DEBUG
      home: LoginScreen(),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // fond blanc
      ),
    );
  }
}
