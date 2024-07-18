import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:musicify/utils/utils.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AlbumScreen extends StatelessWidget {
  final AlbumModel album;
  final List<SongModel> songs;
  final AssetsAudioPlayer player;

  const AlbumScreen({
    super.key,
    required this.album,
    required this.songs,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(album.album),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: QueryArtworkWidget(
                    id: album.id,
                    type: ArtworkType.ALBUM,
                    nullArtworkWidget: Container(
                      width: 150,
                      height: 150,
                      color: Colors.grey,
                      child: const Center(
                        child: Icon(Icons.album, size: 50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.album,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        album.artist ?? 'Unknown Artist',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return AlbumSongListItem(song: songs[index], player: player);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final playlist = Playlist(
            audios: songs
                .map((song) => Audio.file(song.data,
                    metas: Metas(
                      title: song.title,
                      artist: song.artist,
                      album: song.album,
                    )))
                .toList(),
          );
          await player.open(playlist,
              autoStart: true, showNotification: true, loopMode: LoopMode.playlist);
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}

class AlbumSongListItem extends StatelessWidget {
  final SongModel song;
  final AssetsAudioPlayer player;

  const AlbumSongListItem({
    super.key,
    required this.song,
    required this.player,
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
      trailing: Text(
        durationFormat(Duration(milliseconds: song.duration ?? 0)),
        style: const TextStyle(color: Colors.white60),
      ),
      onTap: () async {
        await player.open(
          Audio.file(song.data,
              metas: Metas(
                title: song.title,
                artist: song.artist,
                album: song.album,
              )),
          autoStart: true,
          showNotification: true,
        );
      },
    );
  }

 
}