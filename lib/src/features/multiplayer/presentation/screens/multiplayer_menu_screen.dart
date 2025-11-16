import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MultiplayerMenuScreen extends StatefulWidget {
  const MultiplayerMenuScreen({super.key});

  @override
  State<MultiplayerMenuScreen> createState() => _MultiplayerMenuScreenState();
}

class _MultiplayerMenuScreenState extends State<MultiplayerMenuScreen> {
  late VideoPlayerController _videoController;
  String? player1Selection;
  String? player2Selection;

  bool get isPlayer1Turn => player1Selection == null;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.asset('assets/videos/multi_fondo.mp4')
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

  void _selectCharacter(String character) {
    setState(() {
      if (isPlayer1Turn) {
        player1Selection = character;
      } else {
        if (player2Selection == null && character != player1Selection) {
          player2Selection = character;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selección de Personaje'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          // Player 1 selection area
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            top: 50,
            left: player1Selection != null ? 20 : size.width / 2 - 75,
            child: player1Selection != null
                ? CharacterCard(character: player1Selection!)
                : Container(),
          ),

          // Player 2 selection area
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            top: 50,
            right: player2Selection != null ? 20 : size.width / 2 - 75,
            child: player2Selection != null
                ? CharacterCard(character: player2Selection!)
                : Container(),
          ),

          // Character choices
          if (player1Selection == null || player2Selection == null)
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (player1Selection != 'chaac' && player2Selection != 'chaac')
                    GestureDetector(
                      onTap: () => _selectCharacter('chaac'),
                      child: const CharacterCard(character: 'chaac'),
                    ),
                  if (player1Selection != 'pos' && player2Selection != 'pos')
                    GestureDetector(
                      onTap: () => _selectCharacter('pos'),
                      child: const CharacterCard(character: 'pos'),
                    ),
                ],
              ),
            ),

          // Player turn indicator
          if (player1Selection == null || player2Selection == null)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Text(
                isPlayer1Turn ? 'Jugador 1 Elige' : 'Jugador 2 Elige',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class CharacterCard extends StatelessWidget {
  final String character;

  const CharacterCard({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Image.asset('assets/images/ui/${character}_battle.gif'),
    );
  }
}
