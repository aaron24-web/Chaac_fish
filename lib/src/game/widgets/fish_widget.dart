import 'package:flutter/material.dart';
import 'package:pesca_game/src/game/models/fish_model.dart';

class FishWidget extends StatelessWidget {
  final Fish fish;

  const FishWidget({super.key, required this.fish});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: fish.position.dx,
      top: fish.position.dy,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(fish.goesRight ? 0 : 3.14159), // Flip image if going left
        child: Image.asset(
          fish.imagePath,
          width: 80, // A default size for the fish
          errorBuilder: (context, error, stackTrace) {
            // If the image fails to load, show a placeholder
            return Container(
              width: 80,
              height: 40,
              color: Colors.red.withOpacity(0.5),
              child: const Center(child: Icon(Icons.error)),
            );
          },
        ),
      ),
    );
  }
}
