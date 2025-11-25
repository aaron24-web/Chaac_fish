import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pesca_game/src/features/shop/domain/models/shop_item_model.dart';
import 'package:pesca_game/src/game/models/fish_model.dart';
import 'package:pesca_game/src/game/widgets/fish_widget.dart';
import 'package:video_player/video_player.dart';

class Explosion {
  final String id;
  final Offset position;

  Explosion({required this.id, required this.position});
}

class GameScreen extends StatefulWidget {
  final int level;
  final ShopItem? equippedRod;

  const GameScreen({super.key, required this.level, this.equippedRod});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _gameLoop;
  final List<Fish> _fishes = [];
  final List<Explosion> _explosions = [];
  final Random _random = Random();
  late AudioPlayer _sfxPlayer;
  late AudioPlayer _backgroundMusicPlayer;
  bool _isChaacFishing = false;
  int _currentScore = 0;
  int _targetScore = 10;
  Timer? _paralyzeTimer;
  bool _isLloronaScreaming = false;
  late VideoPlayerController _lloronaVideoController;
  bool _isAxolotlAnimating = false;
  late VideoPlayerController _axolotlVideoController;

  // Hardcoded list of available fish. Later, this can be fetched from the DB.
  List<Map<String, dynamic>> _availableFishTypes = [];

  @override
  void initState() {
    super.initState();
    _sfxPlayer = AudioPlayer();
    _backgroundMusicPlayer = AudioPlayer();
    _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);

    // Define base fish for all levels
    _availableFishTypes = [
      {'name': 'blue_fish', 'points': 1, 'type': FishType.normal},
      {'name': 'orange_fish', 'points': 1, 'type': FishType.normal},
      {'name': 'pink_fish', 'points': 1, 'type': FishType.normal},
      {'name': 'red_fish', 'points': 1, 'type': FishType.normal},
      {'name': 'cabello_special', 'points': 5, 'type': FishType.especial_bueno},
      {
        'name': 'mariachi_special',
        'points': 5,
        'type': FishType.especial_bueno,
      },
    ];

    // Add dangerous fish for level 2 and above
    if (widget.level >= 2) {
      _availableFishTypes.addAll([
        {'name': 'snake_danger', 'points': -5, 'type': FishType.danger},
        {'name': 'llorona_danger', 'points': 0, 'type': FishType.danger},
        {'name': 'diablo_danger', 'points': -10, 'type': FishType.danger},
      ]);

      // Bomb fish only in levels 2 and 3
      if (widget.level == 2 || widget.level == 3) {
        _availableFishTypes.add({
          'name': 'bomb_fish',
          'points': -15,
          'type': FishType.danger,
        });
      }
    }

    // Add exclusive fish for level 3
    if (widget.level == 3) {
      _availableFishTypes.add({
        'name': 'axolott_special',
        'points': 0,
        'type': FishType.especial_bueno,
      });
    }

    String videoPath;
    String audioPath;

    switch (widget.level) {
      case 1:
        videoPath = 'assets/videos/utm_fondo.mp4';
        audioPath = 'audio/music/nivel1_sound.mp3';
        _targetScore = 10;
        break;
      case 2:
        videoPath = 'assets/videos/iza_nivel2.mp4';
        audioPath = 'audio/music/nivel2.mp3';
        _targetScore = 20;
        break;
      case 3:
        videoPath = 'assets/videos/chichen_fondo.mp4';
        audioPath = 'audio/music/nivel3.mp3';
        _targetScore = 30;
        break;
      default:
        videoPath = 'assets/videos/utm_fondo.mp4';
        audioPath = 'audio/music/nivel1_sound.mp3';
        _targetScore = 10;
    }

    _videoController = VideoPlayerController.asset(videoPath)
      ..initialize().then((_) {
        _videoController.play();
        _videoController.setVolume(0);
        _videoController.setLooping(true);
        setState(() {});
      });

    // Ensure volume is set before playing
    _backgroundMusicPlayer.setVolume(1.0);
    _backgroundMusicPlayer.play(AssetSource(audioPath));

    _gameLoop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _gameLoop.addListener(_updateGame);

    // Spawn a new fish every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (_) {
      _spawnFish();
    });

    if (widget.equippedRod?.abilityCode == 'PARALYZE_CHANCE') {
      _paralyzeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_random.nextDouble() < 0.20 && _fishes.isNotEmpty) {
          final fishToParalyze = _fishes[_random.nextInt(_fishes.length)];
          if (fishToParalyze.speed != 0) {
            setState(() {
              fishToParalyze.speed = 0;
              fishToParalyze.isStunned = true;
            });
            Timer(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  fishToParalyze.speed = fishToParalyze.originalSpeed;
                  fishToParalyze.isStunned = false;
                });
              }
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _gameLoop.removeListener(_updateGame);
    _gameLoop.dispose();
    _sfxPlayer.dispose();
    _backgroundMusicPlayer.dispose();
    _paralyzeTimer?.cancel();
    if (_isLloronaScreaming) {
      _lloronaVideoController.dispose();
    }
    if (_isAxolotlAnimating) {
      _axolotlVideoController.dispose();
    }
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
    if (!_gameLoop.isAnimating) return;
    if (!mounted) return;

    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final fishTypeData =
        _availableFishTypes[_random.nextInt(_availableFishTypes.length)];

    final bool goesRight = _random.nextBool();

    // Fix: Adjust vertical position to prevent fish from being cut off at the bottom
    // Spawn between 60% of screen height and (Screen Height - 150px - bottom padding)
    final double minY =
        screenSize.height *
        0.50; // Subí un poco el inicio (50%) para dar más espacio
    final double maxY = screenSize.height - 150.0 - padding.bottom;
    // Ensure maxY is greater than minY to avoid range error
    final double safeMaxY = maxY > minY ? maxY : minY + 50;

    final double verticalPosition =
        minY + _random.nextDouble() * (safeMaxY - minY);

    final double horizontalPosition = goesRight ? -80 : screenSize.width;
    final double speed =
        _random.nextDouble() * 2 + 1; // Speed between 1.0 and 3.0

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

  void _playSoundEffect(String soundAsset) {
    // Eliminamos la reducción de volumen de la música de fondo para evitar bugs
    // donde el volumen no regresa a la normalidad si se reproducen muchos sonidos.
    // _backgroundMusicPlayer.setVolume(0.2);
    _sfxPlayer.play(AssetSource(soundAsset));
    // _sfxPlayer.onPlayerComplete.first.then((_) {
    //   _backgroundMusicPlayer.setVolume(1.0);
    // });
  }

  void _handleLloronaEffect() {
    _gameLoop.stop();
    _backgroundMusicPlayer.pause();

    setState(() {
      _fishes.clear();
    });

    _lloronaVideoController = VideoPlayerController.asset(
      'assets/videos/scream_llorona.mp4',
    );

    void listener() {
      if (_lloronaVideoController.value.isInitialized &&
          !_lloronaVideoController.value.isPlaying &&
          _lloronaVideoController.value.position >=
              _lloronaVideoController.value.duration) {
        _lloronaVideoController.removeListener(listener);
        _lloronaVideoController.dispose();

        setState(() {
          _isLloronaScreaming = false;
        });
        _backgroundMusicPlayer.resume();
        _gameLoop.repeat();
      }
    }

    _lloronaVideoController.addListener(listener);

    _lloronaVideoController
        .initialize()
        .then((_) {
          setState(() {
            _isLloronaScreaming = true;
          });
          _lloronaVideoController.play();
          _sfxPlayer.play(AssetSource('audio/sfx/llorona.mp3'));
        })
        .catchError((error) {
          debugPrint("Error loading Llorona video: $error");
          _backgroundMusicPlayer.resume();
          _gameLoop.repeat();
        });
  }

  void _handleBombExplosion(Fish bombFish) async {
    const explosionRadius = 150.0;

    // Play bomb sound from second 4 to second 6 (2 seconds duration)
    final bombPlayer = AudioPlayer();
    await bombPlayer.play(
      AssetSource('audio/sfx/bomba.mp3'),
      position: const Duration(seconds: 4),
    );

    // Stop after 2 seconds (from second 4 to second 6)
    Timer(const Duration(seconds: 2), () {
      bombPlayer.stop();
      bombPlayer.dispose();
    });

    setState(() {
      // Remove the bomb fish
      _fishes.remove(bombFish);

      // Find and remove all fish within explosion radius
      final fishToRemove = <Fish>[];
      for (var fish in _fishes) {
        final distance = sqrt(
          pow(fish.position.dx - bombFish.position.dx, 2) +
              pow(fish.position.dy - bombFish.position.dy, 2),
        );

        if (distance <= explosionRadius) {
          fishToRemove.add(fish);
          // Subtract points for destroyed fish (don't give points)
          if (fish.type == FishType.normal ||
              fish.type == FishType.especial_bueno) {
            _currentScore -= fish.points;
          }
        }
      }

      // Remove all fish caught in explosion
      for (var fish in fishToRemove) {
        _fishes.remove(fish);
      }

      // Apply bomb penalty
      _currentScore += bombFish.points; // -15 points
    });
  }

  void _handleAxolotlEffect() {
    _gameLoop.stop();
    _backgroundMusicPlayer.pause();

    setState(() {
      for (var fish in _fishes) {
        if (fish.type == FishType.danger) {
          fish.type = FishType.especial_bueno;
          fish.points = 5;
          fish.imageName = _random.nextBool()
              ? 'cabello_special'
              : 'mariachi_special';
        }
      }
    });

    _axolotlVideoController = VideoPlayerController.asset(
      'assets/videos/axo_anima.mp4',
    );

    void listener() {
      if (_axolotlVideoController.value.isInitialized &&
          !_axolotlVideoController.value.isPlaying &&
          _axolotlVideoController.value.position >=
              _axolotlVideoController.value.duration) {
        _axolotlVideoController.removeListener(listener);
        _axolotlVideoController.dispose();

        setState(() {
          _isAxolotlAnimating = false;
        });
        _backgroundMusicPlayer.resume();
        _gameLoop.repeat();
      }
    }

    _axolotlVideoController.addListener(listener);

    _axolotlVideoController
        .initialize()
        .then((_) {
          setState(() {
            _isAxolotlAnimating = true;
          });
          _axolotlVideoController.play();
        })
        .catchError((error) {
          debugPrint("Error loading Axolotl video: $error");
          _backgroundMusicPlayer.resume();
          _gameLoop.repeat();
        });
  }

  void _onFishTapped(Fish fish) {
    // Handle special fish effects first
    switch (fish.imageName) {
      case 'axolott_special':
        // 20% probability (2 out of 10) to trigger animation
        if (Random().nextInt(10) < 2) {
          _handleAxolotlEffect();
        }
        break;
      case 'snake_danger':
        _playSoundEffect('audio/sfx/snake.mp3');
        break;
      case 'llorona_danger':
        // 20% probability (2 out of 10) to trigger animation
        if (Random().nextInt(10) < 2) {
          _handleLloronaEffect();
        }
        break;
      case 'diablo_danger':
        _playSoundEffect('audio/sfx/diablo.mp3');
        break;
      case 'cabello_special':
        _playSoundEffect('audio/sfx/cabello.mp3');
        break;
      case 'bomb_fish':
        _handleBombExplosion(fish);
        break;
    }

    // Don't process tap for Llorona, Axolotl or Bomb (already handled above)
    if (fish.imageName == 'llorona_danger' ||
        fish.imageName == 'axolott_special' ||
        fish.imageName == 'bomb_fish') {
      if (fish.imageName != 'bomb_fish') {
        setState(() {
          _fishes.remove(fish);
        });
      }
      return;
    }

    final explosion = Explosion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: fish.position,
    );

    int pointsToAdd = fish.points;
    if (widget.equippedRod != null) {
      final abilityCode = widget.equippedRod!.abilityCode;
      if (abilityCode == 'EXTRA_POINT_CHANCE' && _random.nextDouble() < 0.25) {
        pointsToAdd += 1;
      }
      if (abilityCode == 'DOUBLE_POINTS_CHANCE' &&
          _random.nextDouble() < 0.15) {
        pointsToAdd *= 2;
      }
    }

    setState(() {
      _isChaacFishing = true;
      _explosions.add(explosion);
      _fishes.remove(fish);
      _currentScore += pointsToAdd;
    });

    if (_currentScore >= _targetScore) {
      _handleWin();
    }

    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isChaacFishing = false;
      });
    });

    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _explosions.remove(explosion);
      });
    });
  }

  void _handleWin() {
    _gameLoop.stop();
    _backgroundMusicPlayer.stop();
    _videoController.pause();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¡Ganaste!'),
          content: Text('Alcanzaste los $_targetScore puntos.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(
                  context,
                ).pop(_currentScore); // Go back with a win result
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLloronaScreaming) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: AspectRatio(
            aspectRatio: _lloronaVideoController.value.aspectRatio,
            child: VideoPlayer(_lloronaVideoController),
          ),
        ),
      );
    }

    if (_isAxolotlAnimating) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: AspectRatio(
            aspectRatio: _axolotlVideoController.value.aspectRatio,
            child: VideoPlayer(_axolotlVideoController),
          ),
        ),
      );
    }

    final chaacAnimation = _isChaacFishing
        ? 'assets/images/animations/chaac_pesco.gif'
        : 'assets/images/animations/chaac_estatico.gif';

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
                chaacAnimation,
                width: 200,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, color: Colors.red, size: 50);
                },
              ),
            ),
          ),

          // Fish Widgets
          ..._fishes.map(
            (fish) => FishWidget(
              key: ValueKey(fish.id),
              fish: fish,
              onTapped: _onFishTapped,
            ),
          ),

          // Explosion Widgets
          ..._explosions.map(
            (explosion) => ExplosionWidget(explosion: explosion),
          ),

          // UI on top
          SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _onBackPressed,
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Puntaje: $_currentScore / $_targetScore',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.equippedRod != null)
                          EquippedRodWidget(rod: widget.equippedRod!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExplosionWidget extends StatelessWidget {
  final Explosion explosion;

  const ExplosionWidget({super.key, required this.explosion});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: explosion.position.dx,
      top: explosion.position.dy,
      child: Image.asset(
        'assets/images/animations/gota_explosion.gif',
        width: 80,
      ),
    );
  }
}

class EquippedRodWidget extends StatefulWidget {
  final ShopItem rod;

  const EquippedRodWidget({super.key, required this.rod});

  @override
  State<EquippedRodWidget> createState() => _EquippedRodWidgetState();
}

class _EquippedRodWidgetState extends State<EquippedRodWidget> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(widget.rod.videoPath)
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: _videoController.value.isInitialized
          ? VideoPlayer(_videoController)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
