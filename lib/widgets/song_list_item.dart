import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongListItem extends StatelessWidget {
  final SongModel song;
  final AssetsAudioPlayer player;
  final VoidCallback onTap;
  final bool isSelected;

  const SongListItem({
    super.key,
    required this.song,
    required this.player,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        song.title ?? 'Unknown Title',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        song.artist ?? 'Unknown Artist',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isSelected ? Colors.blue.withOpacity(0.7) : Colors.white70,
        ),
      ),
      leading: _buildArtwork(),
      onTap: onTap,
      trailing:
          isSelected ? const Icon(Icons.equalizer, color: Colors.blue) : null,
    );
  }

  Widget _buildArtwork() {
    if (song.id != null) {
      return QueryArtworkWidget(
        id: song.id!,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: _defaultArtwork(),
      );
    } else {
      return _defaultArtwork();
    }
  }

  Widget _defaultArtwork() {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey,
      ),
      child: const Icon(Icons.music_note, color: Colors.white),
    );
  }
}