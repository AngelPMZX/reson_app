import 'package:flutter/material.dart';

void main() {
  runApp(const ResonApp());
}

class ResonApp extends StatelessWidget {
  const ResonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reson App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            '¡Bienvenidos a Reson!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
