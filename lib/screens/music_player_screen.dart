import 'package:flutter/material.dart';
import 'package:musicify/widgets/player_controls.dart';
import 'package:musicify/widgets/track_list.dart';
import 'package:musicify/services/audio_service.dart';
import 'package:musicify/models/track.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({Key? key}) : super(key: key);

  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioService _audioService = AudioService();
  List<Track> _tracks = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadTracks() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tracks = await _audioService.loadTracks();
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tracks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playPause() {
    if (_tracks.isNotEmpty) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
      _isPlaying
          ? _audioService.play(_tracks[_currentIndex])
          : _audioService.pause();
    }
  }

  void _nextTrack() {
    if (_tracks.isNotEmpty) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _tracks.length;
        _isPlaying = true;
      });
      _audioService.play(_tracks[_currentIndex]);
    }
  }

  void _previousTrack() {
    if (_tracks.isNotEmpty) {
      setState(() {
        _currentIndex = (_currentIndex - 1 + _tracks.length) % _tracks.length;
        _isPlaying = true;
      });
      _audioService.play(_tracks[_currentIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Musicify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _loadTracks,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TrackList(
                    tracks: _tracks,
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      setState(() {
                        _currentIndex = index;
                        _isPlaying = true;
                      });
                      _audioService.play(_tracks[_currentIndex]);
                    },
                  ),
          ),
          PlayerControls(
            isPlaying: _isPlaying,
            onPlayPause: _playPause,
            onNext: _nextTrack,
            onPrevious: _previousTrack,
          ),
        ],
      ),
    );
  }
}
