import 'package:flutter/material.dart';
import '../widgets/player_controls.dart';
import '../services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = AudioService();
  String? _currentSongPath;

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
          PlayerControls(
            audioService: _audioService,
            currentSongPath: _currentSongPath,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}