import 'package:flutter/material.dart';
import 'package:pesca_game/src/game/widgets/scenes/game_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tddnkbawgglmwyzmykij.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRkZG5rYmF3Z2dsbXd5em15a2lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyMTA3NjQsImV4cCI6MjA3ODc4Njc2NH0.Xmk4dERCWpaIKfk0kZ-KNsTQk6WUzjpN2i6fhKoGyN4',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pesca Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const GameScreen(),
    );
  }
}
