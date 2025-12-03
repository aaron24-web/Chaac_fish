import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoryRepository {
  final SupabaseClient _supabaseClient;

  StoryRepository(this._supabaseClient);

  Future<int> getUnlockedLevel(String userId) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select('story_level_unlocked')
          .eq('id', userId)
          .single();
      return response['story_level_unlocked'] as int;
    } catch (e) {
      // Handle errors, e.g., user not found or network issues
      debugPrint('Error getting unlocked level: $e');
      return 1;
    }
  }

  Future<void> completeLevel(String userId, int level, int score) async {
    debugPrint('🚀 StoryRepository: Attempting to complete level $level for user $userId with score $score');
    try {
      await _supabaseClient.rpc(
        'complete_level',
        params: {
          'user_id_param': userId,
          'level_param': level,
          'score_param': score,
        },
      );
      debugPrint('✅ StoryRepository: Level completion RPC successful');
    } catch (e) {
      // Handle errors, e.g., network issues or function not found
      debugPrint('❌ StoryRepository: Error completing level: $e');
      rethrow;
    }
  }
}
