import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ArtistScreen extends StatelessWidget {
  final ArtistModel artist;
  final List<SongModel> songs;
  final AssetsAudioPlayer player;

  const ArtistScreen({
    super.key,
    required this.artist,
    required this.songs,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(artist.artist),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: QueryArtworkWidget(
              id: artist.id,
              type: ArtworkType.ARTIST,
              nullArtworkWidget: CircleAvatar(
                radius: 75,
                child: Text(
                  artist.artist[0].toUpperCase(),
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.album ?? ''),
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
              autoStart: true,
              showNotification: true,
              loopMode: LoopMode.playlist);
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
