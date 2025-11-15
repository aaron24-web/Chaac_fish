import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pesca_game/src/features/shop/presentation/screens/shop_placeholder_screen.dart';

class StoryMenuScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;
  const StoryMenuScreen({super.key, required this.audioPlayer});

  @override
  State<StoryMenuScreen> createState() => _StoryMenuScreenState();
}

class _StoryMenuScreenState extends State<StoryMenuScreen> {
  // Hardcoded for now, will be fetched from Supabase later
  final int unlockedLevel = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.store),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ShopPlaceholderScreen(),
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
                      final isLocked = level > unlockedLevel;
                      return LevelCard(
                        level: level,
                        isLocked: isLocked,
                        onTap: isLocked
                            ? null
                            : () {
                                // Navigate to the game screen for this level
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
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.all(16),
        child: SizedBox(
          width: 150,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Nivel $level',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (isLocked)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 50,
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
