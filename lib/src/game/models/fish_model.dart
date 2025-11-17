import 'package:flutter/material.dart';

enum FishType { normal, especial_bueno, trampa }

class Fish {
  final String id;
  final String imageName;
  final int points;
  final FishType type;
  Offset position;
  double speed;
  final double originalSpeed;
  final bool goesRight; // Direction of movement
  bool isStunned;

  Fish({
    required this.id,
    required this.imageName,
    required this.points,
    required this.type,
    required this.position,
    required double speed,
    required this.goesRight,
    this.isStunned = false,
  })  : speed = speed,
        originalSpeed = speed;

  // Method to get the full image path
  String get imagePath => 'assets/images/fish/$imageName.png';
}
