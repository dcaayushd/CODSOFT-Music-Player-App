import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musicify/screens/album_screen.dart';

class AlbumGridItem extends StatelessWidget {
  final AlbumModel album;
  final List<SongModel> songs;
  final AssetsAudioPlayer player;

  const AlbumGridItem({
    super.key,
    required this.album,
    required this.songs,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumScreen(
              album: album,
              songs: songs,
              player: player,
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: QueryArtworkWidget(
                id: album.id,
                type: ArtworkType.ALBUM,
                nullArtworkWidget: Container(
                  color: Colors.grey,
                  child: const Center(
                    child: Icon(Icons.album, size: 50),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                album.album,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}