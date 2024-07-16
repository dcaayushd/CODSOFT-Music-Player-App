import 'package:flutter/material.dart';
import '../widgets/player_controls.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My List'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.music_note, size: 100, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          const Text(
            'No song selected',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Artist',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const Spacer(),
          const PlayerControls(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}