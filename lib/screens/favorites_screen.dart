import 'package:flutter/material.dart';
import 'package:musicify/services/favorites_service.dart';
import 'package:musicify/services/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  FavoritesScreenState createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final AudioService _audioService = AudioService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favoritesService.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorites yet'));
          }

          final favorites = snapshot.data!;
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final song = favorites[index];
              return Dismissible(
                key: Key(song['id']),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _favoritesService.removeFavorite(song['id']);
                  setState(() {
                    favorites.removeAt(index);
                  });
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  leading: QueryArtworkWidget(
                    id: int.parse(song['artworkId'] ?? '0'),
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: const Icon(Icons.music_note),
                  ),
                  title: Text(song['title'] ?? 'Unknown Title'),
                  subtitle: Text(song['artist'] ?? 'Unknown Artist'),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      _favoritesService.removeFavorite(song['id']);
                      setState(() {
                        favorites.removeAt(index);
                      });
                    },
                  ),
                  onTap: () {
                    _playOrPauseSong(song);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _playOrPauseSong(Map<String, dynamic> song) async {
    final currentlyPlayingSongId =
        _audioService.player.current.value?.audio.audio.metas.id;
    final isPlaying = _audioService.player.isPlaying.value;

    if (currentlyPlayingSongId == song['id'] && isPlaying) {
      await _audioService.player.pause();
    } else if (currentlyPlayingSongId == song['id'] && !isPlaying) {
      await _audioService.player.play();
    } else {
      final audio = Audio.file(
        song['data'],
        metas: Metas(
          id: song['id'],
          title: song['title'],
          artist: song['artist'],
        ),
      );
      await _audioService.player.open(audio, showNotification: true);
    }
  }
}
