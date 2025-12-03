import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pesca_game/src/features/multiplayer/data/repositories/multiplayer_repository.dart';
import 'package:pesca_game/src/game/models/fish_model.dart';
import 'package:pesca_game/src/game/widgets/fish_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final String sessionId;
  final bool isHost;
  final String playerId;

  const MultiplayerGameScreen({
    super.key,
    required this.sessionId,
    required this.isHost,
    required this.playerId,
  });

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _gameLoop;
  late MultiplayerRepository _multiplayerRepository;
  
  final List<Fish> _fishes = [];
  final Random _random = Random();
  late AudioPlayer _sfxPlayer;
  late AudioPlayer _backgroundMusicPlayer;
  
  Timer? _gameTimer;
  int _remainingTime = 120;
  bool _isGameOver = false;
  
  bool _isWaitingForOpponent = true;
  int _myScore = 0;
  int _opponentScore = 0;
  
  StreamSubscription? _gameEventsSubscription;
  StreamSubscription? _sessionSubscription;

  // Available fish types (simplified for multiplayer)
  final List<Map<String, dynamic>> _availableFishTypes = [
    {'name': 'blue_fish', 'points': 1, 'type': FishType.normal},
    {'name': 'orange_fish', 'points': 1, 'type': FishType.normal},
    {'name': 'pink_fish', 'points': 1, 'type': FishType.normal},
    {'name': 'red_fish', 'points': 1, 'type': FishType.normal},
  ];

  final Set<String> _caughtFishIds = {}; // Track locally caught fish to prevent resurrection

  @override
  void initState() {
    super.initState();
    debugPrint('🎮 MultiplayerGameScreen: initState');
    _multiplayerRepository = MultiplayerRepository(Supabase.instance.client);
    _sfxPlayer = AudioPlayer();
    _backgroundMusicPlayer = AudioPlayer();
    _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);

    _setupVideoAndAudio();
    _setupGameLoop();
    _setupMultiplayerListeners();
  }

  void _setupVideoAndAudio() {
    debugPrint('🎥 Setting up Video and Audio');
    _videoController = VideoPlayerController.asset('assets/videos/utm_fondo.mp4')
      ..initialize().then((_) {
        debugPrint('✅ Video Initialized');
        _videoController.play();
        _videoController.setVolume(0);
        _videoController.setLooping(true);
        setState(() {});
      }).catchError((e) {
        debugPrint('❌ Error initializing video: $e');
      });

    _backgroundMusicPlayer.setVolume(0.5);
    _backgroundMusicPlayer.play(AssetSource('audio/music/nivel1_sound.mp3'));
  }

  void _setupGameLoop() {
    debugPrint('🔄 Setting up Game Loop');
    _gameLoop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _gameLoop.addListener(_updateGame);

    // Only host spawns fish
    if (widget.isHost) {
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_isGameOver) {
          timer.cancel();
          return;
        }
        if (!_isWaitingForOpponent) {
          _spawnFish();
        }
      });
    }
  }

  void _setupMultiplayerListeners() {
    debugPrint('📡 Setting up Multiplayer Listeners');
    // Listen for session status changes (waiting -> playing)
    _sessionSubscription = _multiplayerRepository
        .subscribeToSession(widget.sessionId)
        .listen((sessionData) {
      // debugPrint('📥 Session Update: ${sessionData['status']}'); // Commented out to reduce noise
      if (sessionData['status'] == 'playing') {
        if (_isWaitingForOpponent) {
          setState(() {
            _isWaitingForOpponent = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡El oponente se ha unido! ¡A pescar!')),
          );
        }

        // Sync timer and fish
        final gameState = sessionData['game_state'];
        if (gameState != null) {
          // Timer
          if (gameState['startTime'] != null) {
            final startTime = DateTime.parse(gameState['startTime']);
            final duration = gameState['duration'] ?? 120;
            final elapsed = DateTime.now().difference(startTime).inSeconds;
            final remaining = duration - elapsed;

            if (remaining <= 0 && !_isGameOver) {
              _endGame();
            } else if (remaining > 0) {
               setState(() {
                 _remainingTime = remaining;
               });
               _startLocalTimer();
            }
          }
          
          // Sync Fish (Initial Load / Rejoin)
          if (gameState['activeFish'] != null) {
            final List activeFishData = gameState['activeFish'];
            final Set<String> currentIds = _fishes.map((f) => f.id).toSet();
            
            for (var fishData in activeFishData) {
              final String fishId = fishData['id'];
              // Only add if not present AND not recently caught locally
              if (!currentIds.contains(fishId)) {
                if (_caughtFishIds.contains(fishId)) {
                  // debugPrint('🛡️ Blocked resurrection of caught fish $fishId');
                } else {
                  // debugPrint('🐟 Adding fish from DB: $fishId');
                  setState(() {
                    _fishes.add(Fish.fromJson(fishData));
                  });
                }
              }
            }
          }
        }
      }
      
      // Update scores from DB
      if (mounted) {
        final List players = List.from(sessionData['players'] ?? []);
        int opponentScore = 0;

        for (var p in players) {
          if (p['id'] != widget.playerId) {
            opponentScore = p['score'] ?? 0;
          }
        }

        setState(() {
          // Only update opponent score from DB to prevent overwriting local optimistic score
          _opponentScore = opponentScore;
        });
      }
    });

    // Listen for game events (fish spawn, fish caught)
    _gameEventsSubscription = _multiplayerRepository
        .listenToGameEvents(widget.sessionId)
        .listen((event) {
      final type = event['type'];
      final payload = event['payload'];

      if (type == 'spawn_fish' && !widget.isHost) {
        // ... (spawn logic)
      } else if (type == 'fish_caught') {
        // Both receive fish caught
        final fishId = payload['fishId'];
        final playerId = payload['playerId'];
        
        debugPrint('🎣 Fish Caught: $fishId by $playerId');

        setState(() {
          _fishes.removeWhere((f) => f.id == fishId);
          _caughtFishIds.add(fishId); // Mark as caught
          
          // Optimistic Score Update (Real-time fix)
          if (playerId == widget.playerId) {
             // Already updated locally in _onFishTapped
          } else {
             // Update opponent score locally immediately
             _opponentScore += 1; 
          }
        });
        
        // ... (host sync logic)
      }
    });
  }



  void _startLocalTimer() {
    if (_gameTimer != null && _gameTimer!.isActive) return;
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _endGame();
      }
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    if (_isGameOver) return;

    setState(() {
      _isGameOver = true;
      _remainingTime = 0;
    });

    String message;
    if (_myScore > _opponentScore) {
      message = '¡Ganaste!';
    } else if (_myScore < _opponentScore) {
      message = 'Perdiste...';
    } else {
      message = '¡Empate!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Tiempo Agotado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Tu puntaje: $_myScore'),
            Text('Oponente: $_opponentScore'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to menu
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _gameLoop.dispose();
    _sfxPlayer.dispose();
    _backgroundMusicPlayer.dispose();
    _gameEventsSubscription?.cancel();
    _sessionSubscription?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }

  void _updateGame() {
    if (!mounted || _isGameOver) return;

    final screenSize = MediaQuery.of(context).size;
    final List<Fish> toRemove = [];

    for (final fish in _fishes) {
      if (fish.goesRight) {
        fish.position = fish.position.translate(fish.speed, 0);
        if (fish.position.dx > screenSize.width) {
          toRemove.add(fish);
        }
      } else {
        fish.position = fish.position.translate(-fish.speed, 0);
        if (fish.position.dx < -80) {
          toRemove.add(fish);
        }
      }
    }

    if (toRemove.isNotEmpty) {
      setState(() {
        _fishes.removeWhere((fish) => toRemove.contains(fish));
      });
      
      // If host, update DB to remove fish that swam away
      if (widget.isHost) {
         _updateActiveFishInDB();
      }
    } else {
      setState(() {});
    }
  }

  void _spawnFish() {
    if (!mounted || _isGameOver) return;

    final screenSize = MediaQuery.of(context).size;
    final fishTypeData =
        _availableFishTypes[_random.nextInt(_availableFishTypes.length)];

    final bool goesRight = _random.nextBool();
    final double minY = screenSize.height * 0.2;
    final double maxY = screenSize.height * 0.8;
    final double verticalPosition =
        minY + _random.nextDouble() * (maxY - minY);

    final double horizontalPosition = goesRight ? -80 : screenSize.width;
    final double speed = _random.nextDouble() * 2 + 1;

    final newFish = Fish(
      id: DateTime.now().millisecondsSinceEpoch.toString() + widget.playerId,
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

    // Broadcast spawn event
    _multiplayerRepository.broadcastGameEvent(widget.sessionId, {
      'type': 'spawn_fish',
      'payload': {
        ...newFish.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    });
    
    // Update DB state
    _updateActiveFishInDB();
  }

  void _onFishTapped(Fish fish) {
    if (_isWaitingForOpponent || _isGameOver) return;

    // Optimistic update
    setState(() {
      _fishes.remove(fish);
      _caughtFishIds.add(fish.id); // Mark as caught
      _myScore += fish.points;
    });

    // Broadcast catch event
    _multiplayerRepository.broadcastGameEvent(widget.sessionId, {
      'type': 'fish_caught',
      'payload': {
        'fishId': fish.id,
        'playerId': widget.playerId,
      },
    });

    // Update score in DB
    _multiplayerRepository.updateScore(
      widget.sessionId,
      widget.playerId,
      _myScore,
      widget.isHost,
    );
    
    // If host, update active fish in DB
    if (widget.isHost) {
      _updateActiveFishInDB();
    }
  }
  
  void _updateActiveFishInDB() {
    final activeFishList = _fishes.map((f) => f.toJson()).toList();
    _multiplayerRepository.updateGameState(widget.sessionId, {
      'activeFish': activeFishList,
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
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

          // Waiting Overlay
          if (_isWaitingForOpponent)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'Esperando oponente...',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      'ID de Partida: ${widget.sessionId}',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

          // Fishes
          ..._fishes.map(
            (fish) => FishWidget(
              key: ValueKey(fish.id),
              fish: fish,
              onTapped: _onFishTapped,
            ),
          ),

          // UI (Scores and Timer)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Timer
                  if (!_isWaitingForOpponent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatTime(_remainingTime),
                        style: TextStyle(
                          color: _remainingTime < 10 ? Colors.red : Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // My Score
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Tú',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$_myScore',
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      // Opponent Score
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Oponente',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$_opponentScore',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
