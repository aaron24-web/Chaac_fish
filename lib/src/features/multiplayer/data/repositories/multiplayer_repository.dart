import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pesca_game/src/game/models/fish_model.dart';

class MultiplayerRepository {
  final SupabaseClient _supabase;

  MultiplayerRepository(this._supabase);

  // Create a new game session
  Future<String> createSession(String hostId) async {
    print("Creating session in table: game_rooms");
    final response = await _supabase
        .from('game_rooms')
        .insert({
          'host_id': hostId,
          'status': 'waiting',
          'players': [
            {'id': hostId, 'score': 0, 'role': 'host'}
          ],
          'game_state': {
            'activeFish': [],
          },
        })
        .select()
        .single();
    return response['id'];
  }

  // Join an existing session
  Future<void> joinSession(String sessionId, String guestId) async {
    final room = await _supabase
        .from('game_rooms')
        .select('players, game_state')
        .eq('id', sessionId)
        .single();
    
    final List players = List.from(room['players'] ?? []);
    // Avoid adding duplicate if already joined
    if (!players.any((p) => p['id'] == guestId)) {
      players.add({'id': guestId, 'score': 0, 'role': 'guest'});
    }

    final Map<String, dynamic> gameState = Map.from(room['game_state'] ?? {});
    if (!gameState.containsKey('startTime')) {
       gameState['startTime'] = DateTime.now().toIso8601String();
       gameState['duration'] = 120;
    }
    if (!gameState.containsKey('activeFish')) {
      gameState['activeFish'] = [];
    }

    await _supabase.from('game_rooms').update({
      'players': players,
      'status': 'playing',
      'game_state': gameState,
    }).eq('id', sessionId);
  }

  // Subscribe to session updates (e.g., when a guest joins)
  Stream<Map<String, dynamic>> subscribeToSession(String sessionId) {
    return _supabase
        .from('game_rooms')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .map((event) => event.first);
  }

  // Broadcast a game event (e.g., spawn fish, fish caught)
  Future<void> broadcastGameEvent(
      String sessionId, Map<String, dynamic> event) async {
    await _supabase.channel('game_$sessionId').sendBroadcastMessage(
          event: 'game_event',
          payload: event,
        );
  }

  // Listen for game events
  Stream<Map<String, dynamic>> listenToGameEvents(String sessionId) {
    final controller = StreamController<Map<String, dynamic>>();
    
    _supabase
        .channel('game_$sessionId')
        .onBroadcast(event: 'game_event', callback: (payload) {
          controller.add(payload);
        })
        .subscribe();

    return controller.stream;
  }
  
  // Update score in the database
  Future<void> updateScore(String sessionId, String playerId, int score, bool isHost) async {
    final room = await _supabase
        .from('game_rooms')
        .select('players')
        .eq('id', sessionId)
        .single();
    
    final List players = List.from(room['players'] ?? []);
    bool changed = false;
    for (var p in players) {
      if (p['id'] == playerId) {
        p['score'] = score;
        changed = true;
      }
    }

    if (changed) {
      await _supabase.from('game_rooms').update({
        'players': players,
      }).eq('id', sessionId);
    }
  }

  // Update game state (e.g., active fish)
  Future<void> updateGameState(String sessionId, Map<String, dynamic> newState) async {
    final room = await _supabase
        .from('game_rooms')
        .select('game_state')
        .eq('id', sessionId)
        .single();
    
    final currentGameState = Map<String, dynamic>.from(room['game_state'] ?? {});
    currentGameState.addAll(newState);

    await _supabase.from('game_rooms').update({
      'game_state': currentGameState,
    }).eq('id', sessionId);
  }
}
