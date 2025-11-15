import 'package:flutter/material.dart';

class ShopPlaceholderScreen extends StatelessWidget {
  const ShopPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
      ),
      body: const Center(
        child: Text('Tienda en creación'),
      ),
    );
  }
}
