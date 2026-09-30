import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Movie Database',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Open Movie Database'),
        ),
        body: const Center(
          child: Text('Catálogo de filmes'),
        ),
      ),
    );
  }
}
