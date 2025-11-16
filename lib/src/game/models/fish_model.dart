import 'package:flutter/material.dart';

enum FishType { normal, especial_bueno, trampa }

class Fish {
  final String id;
  final String imageName;
  final int points;
  final FishType type;
  Offset position;
  final double speed;
  final bool goesRight; // Direction of movement

  Fish({
    required this.id,
    required this.imageName,
    required this.points,
    required this.type,
    required this.position,
    required this.speed,
    required this.goesRight,
  });

  // Method to get the full image path
  String get imagePath => 'assets/images/fish/$imageName.png';
}
