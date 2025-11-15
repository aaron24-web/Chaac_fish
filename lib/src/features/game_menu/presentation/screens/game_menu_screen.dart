import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pesca_game/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:pesca_game/src/features/game_mode/presentation/screens/game_mode_placeholder_screen.dart';
import 'package:pesca_game/src/shared/widgets/custom_button.dart';

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
    _videoController = VideoPlayerController.asset('assets/videos/fondo_menu1.mp4')
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

  void _navigateToGameMode(String mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameModePlaceholderScreen(mode: mode),
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  onPressed: () => _navigateToGameMode('Modo Historia'),
                  text: 'Modo Historia',
                ),
                const SizedBox(height: 24),
                CustomButton(
                  onPressed: () => _navigateToGameMode('Modo Multijugador'),
                  text: 'Modo Multijugador',
                ),
                const SizedBox(height: 48),
                TextButton(
                  onPressed: _logout,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
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
