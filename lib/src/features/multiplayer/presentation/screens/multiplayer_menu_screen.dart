import 'package:flutter/material.dart';
import 'package:pesca_game/src/features/auth/data/repositories/auth_repository.dart';
import 'package:pesca_game/src/features/multiplayer/data/repositories/multiplayer_repository.dart';
import 'package:pesca_game/src/features/multiplayer/presentation/screens/multiplayer_game_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class MultiplayerMenuScreen extends StatefulWidget {
  const MultiplayerMenuScreen({super.key});

  @override
  State<MultiplayerMenuScreen> createState() => _MultiplayerMenuScreenState();
}

class _MultiplayerMenuScreenState extends State<MultiplayerMenuScreen> {
  late VideoPlayerController _videoController;
  late final MultiplayerRepository _multiplayerRepository;
  bool _isLoading = false;
  final TextEditingController _sessionIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _multiplayerRepository = MultiplayerRepository(Supabase.instance.client);
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
    _sessionIdController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    setState(() => _isLoading = true);
    try {
      final userId = AuthRepository.currentUser?['id'];
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final sessionId = await _multiplayerRepository.createSession(userId);
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MultiplayerGameScreen(
              sessionId: sessionId,
              isHost: true,
              playerId: userId,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error creating game: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear partida: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGame() async {
    final sessionId = _sessionIdController.text.trim();
    if (sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un ID de partida')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = AuthRepository.currentUser?['id'];
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await _multiplayerRepository.joinSession(sessionId, userId);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MultiplayerGameScreen(
              sessionId: sessionId,
              isHost: false,
              playerId: userId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al unirse a partida: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multijugador'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
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
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sala de Espera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else ...[
                      ElevatedButton(
                        onPressed: _createGame,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          'Crear Partida',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'O unirse a una existente:',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _sessionIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'ID de la partida',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _joinGame,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Unirse',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
