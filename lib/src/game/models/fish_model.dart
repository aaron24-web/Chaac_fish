import 'package:flutter/material.dart';

enum FishType { normal, especial_bueno, trampa, danger }

class Fish {
  final String id;
  String imageName;
  int points;
  FishType type;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageName': imageName,
      'points': points,
      'type': type.index,
      'x': position.dx,
      'y': position.dy,
      'speed': speed,
      'originalSpeed': originalSpeed,
      'goesRight': goesRight,
      'isStunned': isStunned,
    };
  }

  factory Fish.fromJson(Map<String, dynamic> json) {
    return Fish(
      id: json['id'],
      imageName: json['imageName'],
      points: json['points'],
      type: FishType.values[json['type']],
      position: Offset(json['x'].toDouble(), json['y'].toDouble()),
      speed: json['speed'].toDouble(),
      goesRight: json['goesRight'],
      isStunned: json['isStunned'] ?? false,
    );
  }
}
