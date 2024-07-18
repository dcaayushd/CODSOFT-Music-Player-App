import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musicify/screens/artist_screen.dart';

class ArtistListItem extends StatelessWidget {
  final ArtistModel artist;
  final List<SongModel> songs;
  final AssetsAudioPlayer player;

  const ArtistListItem({
    super.key,
    required this.artist,
    required this.songs,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: QueryArtworkWidget(
        id: artist.id,
        type: ArtworkType.ARTIST,
        nullArtworkWidget: CircleAvatar(
          child: Text(artist.artist[0].toUpperCase()),
        ),
      ),
      title: Text(artist.artist, style: const TextStyle(color: Colors.white)),
      subtitle: Text('${artist.numberOfTracks} songs', style: const TextStyle(color: Colors.white70)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistScreen(
              artist: artist,
              songs: songs,
              player: player,
            ),
          ),
        );
      },
    );
  }
}