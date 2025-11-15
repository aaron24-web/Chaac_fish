import 'package:flutter/material.dart';

class GameModePlaceholderScreen extends StatelessWidget {
  final String mode;

  const GameModePlaceholderScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mode),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Text('Pantalla de $mode en desarrollo'),
      ),
    );
  }
}
