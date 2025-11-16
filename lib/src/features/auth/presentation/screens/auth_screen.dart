import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pesca_game/src/features/auth/presentation/widgets/login_form.dart';
import 'package:pesca_game/src/features/auth/presentation/widgets/register_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late VideoPlayerController _videoController;
  late AudioPlayer _audioPlayer;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/videos/fondo_inicio.mp4')
      ..initialize().then((_) {
        _videoController.play();
        _videoController.setVolume(0);
        _videoController.setLooping(true);
        setState(() {});
      });
    _audioPlayer = AudioPlayer();
    _audioPlayer.play(AssetSource('audio/music/musica_inicio.mp3'));
  }

  @override
  void dispose() {
    _videoController.dispose();
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
                Image.asset('assets/images/ui/logo.gif', height: 150),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    children: [
                      LoginForm(
                        audioPlayer: _audioPlayer,
                        onRegisterPressed: () => _navigateToPage(1),
                      ),
                      RegisterForm(
                        audioPlayer: _audioPlayer,
                        onLoginPressed: () => _navigateToPage(0),
                      ),
                    ],
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
