import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class PlayerControls extends StatefulWidget {
  final AudioService audioService;
  final String? currentSongPath;

  const PlayerControls({
    Key? key,
    required this.audioService,
    this.currentSongPath,
  }) : super(key: key);

  @override
  _PlayerControlsState createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 36),
          onPressed: () {},
        ),
        const SizedBox(width: 32),
        IconButton(
          icon: Icon(
            widget.audioService.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 64,
          ),
          onPressed: () {
            setState(() {
              widget.audioService.playPause(widget.currentSongPath);
            });
          },
        ),
        const SizedBox(width: 32),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 36),
          onPressed: () {},
        ),
      ],
    );
  }
}
