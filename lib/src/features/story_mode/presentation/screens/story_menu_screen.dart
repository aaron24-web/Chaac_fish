import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pesca_game/src/features/game_mode/presentation/screens/game_screen.dart';
import 'package:pesca_game/src/features/shop/domain/models/shop_item_model.dart';
import 'package:pesca_game/src/features/shop/presentation/screens/shop_placeholder_screen.dart';
import 'package:video_player/video_player.dart';

class StoryMenuScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;
  const StoryMenuScreen({super.key, required this.audioPlayer});
  @override
  State<StoryMenuScreen> createState() => _StoryMenuScreenState();
}
class _StoryMenuScreenState extends State<StoryMenuScreen> {
  late VideoPlayerController _videoController;
  int _unlockedLevel = 1;
  ShopItem? _equippedRod;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.asset('assets/videos/fondo_patria.mp4')
          ..initialize().then((_) {
            _videoController.play();
            _videoController.setVolume(0);
            _videoController.setLooping(true);
            setState(() {});
          });
  }
  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _onRodEquipped(ShopItem rod) {
    setState(() {
      _equippedRod = rod;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${rod.name} equipada!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.store, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ShopPlaceholderScreen(
                              onRodEquipped: _onRodEquipped,
                              equippedRod: _equippedRod,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(3, (index) {
                          final level = index + 1;
                          final isLocked = level > _unlockedLevel;
                          return LevelCard(
                            level: level,
                            isLocked: isLocked,
                            onTap: isLocked
                                ? null
                                : () {
                                    widget.audioPlayer.pause();
                                    Navigator.of(context)
                                        .push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            GameScreen(level: level, equippedRod: _equippedRod),
                                      ),
                                    )
                                        .then((result) {
                                      widget.audioPlayer.resume();
                                      setState(() {
                                        _equippedRod = null;
                                        if (result == true && level == _unlockedLevel) {
                                          _unlockedLevel++;
                                        }
                                      });
                                    });
                                  },
                          );
                        }),
                      ),
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

class LevelCard extends StatelessWidget {
  final int level;
  final bool isLocked;
  final VoidCallback? onTap;

  const LevelCard({
    super.key,
    required this.level,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The image path is constructed dynamically based on the level.
    // e.g., assets/images/ui/boton_nivel1.png for level 1.
    final imagePath = 'assets/images/ui/boton_nivel$level.png';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 200,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            // Handling image loading errors by showing a placeholder
            onError: (exception, stackTrace) {
              // Log the error or show a more user-friendly message
              debugPrint('Error loading image: $exception');
            },
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Display the level number with a shadow for better readability
              Text(
                '$level',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              // If the level is locked, show a lock icon with a dark overlay
              if (isLocked)
                Container(
                  color: Colors.black.withOpacity(0.6),
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
