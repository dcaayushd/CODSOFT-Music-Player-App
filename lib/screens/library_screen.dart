import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:musicify/screens/favorites_screen.dart';
import 'package:musicify/screens/playlist_screen.dart';

class LibraryScreen extends StatelessWidget {
  final AssetsAudioPlayer player;
  const LibraryScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey.withOpacity(.2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Library',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(
              Icons.favorite,
              color: Colors.white,
            ),
            title: const Text(
              'Favorites',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.playlist_play,
              color: Colors.white,
            ),
            title: const Text(
              'Playlists',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => PlaylistScreen(player:player,)),
              );
            },
          ),
        ],
      ),
    );
  }
}
