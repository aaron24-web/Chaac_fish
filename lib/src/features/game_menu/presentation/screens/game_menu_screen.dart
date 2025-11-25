import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pesca_game/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:pesca_game/src/features/multiplayer/presentation/screens/multiplayer_menu_screen.dart';
import 'package:pesca_game/src/features/story_mode/presentation/screens/story_menu_screen.dart';

class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  State<GameMenuScreen> createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  late VideoPlayerController _videoController;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.asset('assets/videos/fondo_menu1.mp4')
          ..initialize().then((_) {
            _videoController.play();
            _videoController.setVolume(0);
            _videoController.setLooping(true);
            setState(() {});
          });
    _audioPlayer = AudioPlayer();
    _audioPlayer.play(AssetSource('audio/music/music_menu1.mp3'));
  }

  @override
  void dispose() {
    _videoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _logout() {
    _audioPlayer.stop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  void _navigateToStoryMode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryMenuScreen(audioPlayer: _audioPlayer),
      ),
    );
  }

  void _navigateToMultiplayerMode() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MultiplayerMenuScreen()),
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _navigateToStoryMode,
                  child: Container(
                    width: 300,
                    height: 90,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/madera/TablaRes.png'),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Modo Historia',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 4.0,
                              color: Colors.black,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _navigateToMultiplayerMode,
                  child: Container(
                    width: 300,
                    height: 90,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/madera/TablaRes.png'),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Modo Multijugador',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 4.0,
                              color: Colors.black,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                TextButton(
                  onPressed: _logout,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Cerrar Sesión'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
