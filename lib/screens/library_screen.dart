import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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
              // Navigate to Favorites Songs
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            title: const Text(
              'Create New Playlist',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              // Show dialog to create a new playlist
            },
          ),
          // Add more ListTiles for existing playlists
        ],
      ),
    );
  }
}
