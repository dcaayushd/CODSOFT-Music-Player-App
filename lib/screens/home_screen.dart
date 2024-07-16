import 'package:flutter/material.dart';
import '../widgets/player_controls.dart';
import '../services/audio_service.dart';
import '../services/file_service.dart';
import '../models/song.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = AudioService();
  final FileService _fileService = FileService();
  Song? _currentSong;

  Future<void> _pickSong() async {
    final song = await _fileService.pickSong();
    if (song != null) {
      setState(() {
        _currentSong = song;
      });
      _audioService.playPause(song.filePath);
    }
  }

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
          Text(
            _currentSong?.title ?? 'No song selected',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _currentSong?.artist ?? 'Artist',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const Spacer(),
          PlayerControls(
            audioService: _audioService,
            currentSongPath: _currentSong?.filePath,
          ),
          const SizedBox(height: 48),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickSong,
        child: const Icon(Icons.add),
      ),
    );
  }
}