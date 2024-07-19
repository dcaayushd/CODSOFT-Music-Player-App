import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongListItem extends StatelessWidget {
  final SongModel song;
  final AssetsAudioPlayer player;
  final VoidCallback onTap;
  const SongListItem({
    super.key,
    required this.song,
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        song.title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        song.artist ?? 'Unknown Artist',
        style: const TextStyle(color: Colors.white70),
      ),
      leading: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        // nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white),
        nullArtworkWidget: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey,
          ),
          child: const Icon(Icons.music_note, color: Colors.white),
        ),
      ),
      // onTap: () async {
      //   await player.open(
      //     Audio.file(song.data,
      //         metas: Metas(
      //           title: song.title,
      //           artist: song.artist,
      //           album: song.album,
      //         )),
      //     autoStart: true,
      //     showNotification: true,
      //   );
      // },
      onTap: onTap,
    );
  }
}
