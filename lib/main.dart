import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TelaInicial());
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  String tituloFilme = 'Carregando filme...';

  @override
  void initState() {
    super.initState();
    buscarFilme();
  }

  Future<void> buscarFilme() async {
    final url = Uri.parse(
      'https://www.omdbapi.com/?apikey=564727fa&t=Batman',
    );

    try {
      final resposta = await http.get(url);
      final dados = json.decode(resposta.body);

      setState(() {
        tituloFilme = dados['Title'];
      });
    } catch (_) {
      setState(() {
        tituloFilme = 'Não foi possível carregar o filme.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Movie Database')),
      body: Center(child: Text(tituloFilme)),
    );
  }
}
