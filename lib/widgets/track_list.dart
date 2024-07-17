import 'package:flutter/material.dart';
import 'package:musicify/models/track.dart';

class TrackList extends StatelessWidget {
  final List<Track> tracks;
  final int currentIndex;
  final Function(int) onTap;

  const TrackList({
    Key? key,
    required this.tracks,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          title: Text(track.title),
          subtitle: Text(track.artist),
          leading: const Icon(Icons.music_note),
          trailing: index == currentIndex
              ? const Icon(Icons.play_arrow, color: Colors.blue)
              : null,
          onTap: () => onTap(index),
        );
      },
    );
  }
}