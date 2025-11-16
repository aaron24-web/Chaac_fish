import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pesca_game/src/game/models/fish_model.dart';
import 'package:pesca_game/src/game/widgets/fish_widget.dart';
import 'package:video_player/video_player.dart';

class GameScreen extends StatefulWidget {
  final int level;

  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _gameLoop;
  final List<Fish> _fishes = [];
  final Random _random = Random();
  late AudioPlayer _sfxPlayer;
  late AudioPlayer _backgroundMusicPlayer;

  // Hardcoded list of available fish. Later, this can be fetched from the DB.
  final List<Map<String, dynamic>> _availableFishTypes = [
    {'name': 'blue_fish', 'points': 1, 'type': FishType.normal},
    {'name': 'orange_fish', 'points': 1, 'type': FishType.normal},
    {'name': 'pink_fish', 'points': 1, 'type': FishType.normal},
    {'name': 'red_fish', 'points': 1, 'type': FishType.normal},
    {'name': 'cabello_special', 'points': 5, 'type': FishType.especial_bueno},
    {'name': 'mariachi_special', 'points': 5, 'type': FishType.especial_bueno},
  ];

  @override
  void initState() {
    super.initState();
    _sfxPlayer = AudioPlayer();
    _backgroundMusicPlayer = AudioPlayer();
    _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);

    _videoController = VideoPlayerController.asset('assets/videos/utm_fondo.mp4')
      ..initialize().then((_) {
        _videoController.play();
        _videoController.setVolume(0);
        _videoController.setLooping(true);
        setState(() {});
      });

    _backgroundMusicPlayer.play(AssetSource('audio/music/nivel1_sound.mp3'));

    _gameLoop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _gameLoop.addListener(_updateGame);

    // Spawn a new fish every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (_) {
      _spawnFish();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _gameLoop.removeListener(_updateGame);
    _gameLoop.dispose();
    _sfxPlayer.dispose();
    _backgroundMusicPlayer.dispose();
    super.dispose();
  }

  void _updateGame() {
    if (!mounted) return;

    final screenSize = MediaQuery.of(context).size;
    final List<Fish> toRemove = [];

    for (final fish in _fishes) {
      // Move the fish
      if (fish.goesRight) {
        fish.position = fish.position.translate(fish.speed, 0);
        // Check if off-screen
        if (fish.position.dx > screenSize.width) {
          toRemove.add(fish);
        }
      } else {
        fish.position = fish.position.translate(-fish.speed, 0);
        // Check if off-screen (80 is the approximate fish width)
        if (fish.position.dx < -80) {
          toRemove.add(fish);
        }
      }
    }

    if (toRemove.isNotEmpty) {
      setState(() {
        _fishes.removeWhere((fish) => toRemove.contains(fish));
      });
    } else {
      setState(() {});
    }
  }

  void _spawnFish() {
    if (!mounted) return;

    final screenSize = MediaQuery.of(context).size;
    final fishTypeData =
        _availableFishTypes[_random.nextInt(_availableFishTypes.length)];

    final bool goesRight = _random.nextBool();
    final double verticalPosition =
        _random.nextDouble() * (screenSize.height / 3) +
            (screenSize.height * 2 / 3); // Spawn in the lower 1/3 of the screen
    final double horizontalPosition = goesRight ? -80 : screenSize.width;
    final double speed = _random.nextDouble() * 2 + 1; // Speed between 1.0 and 3.0

    final newFish = Fish(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imageName: fishTypeData['name'],
      points: fishTypeData['points'],
      type: fishTypeData['type'],
      position: Offset(horizontalPosition, verticalPosition),
      speed: speed,
      goesRight: goesRight,
    );

    setState(() {
      _fishes.add(newFish);
    });
  }

  void _onBackPressed() {
    _gameLoop.stop();
    _videoController.pause();
    _backgroundMusicPlayer.pause();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Estás seguro de salir?'),
          content: const Text('Perderás todo tu progreso.'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
                _gameLoop.repeat();
                _videoController.play();
                _backgroundMusicPlayer.resume();
              },
            ),
            TextButton(
              child: const Text('Sí'),
              onPressed: () {
                _backgroundMusicPlayer.stop();
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
          ],
        );
      },
    );
  }

  void _onFishTapped(Fish fish) {
    if (fish.imageName == 'cabello_special') {
      _backgroundMusicPlayer.setVolume(0.2);
      _sfxPlayer.play(AssetSource('audio/sfx/cabello.mp3'));
      _sfxPlayer.onPlayerComplete.first.then((_) {
        _backgroundMusicPlayer.setVolume(1.0);
      });
    }
    setState(() {
      _fishes.remove(fish);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video Background
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),

          // Chaac Image
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Image.asset(
                'assets/images/chaac_cloud_sc_nf.png',
                width: 200,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, color: Colors.red, size: 50);
                },
              ),
            ),
          ),

          // Fish Widgets
          ..._fishes
              .map((fish) => FishWidget(
                    fish: fish,
                    onTapped: _onFishTapped,
                  ))
              .toList(),

          // UI on top
          SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _onBackPressed,
                    ),
                  ],
                ),
                // Game content will go here
              ],
            ),
          ),
        ],
      ),
    );
  }
}
