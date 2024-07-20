import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:musicify/screens/playlist_song_screen.dart';

import '../services/playlist_service.dart';


class PlaylistScreen extends StatefulWidget {
  final AssetsAudioPlayer player;
  const PlaylistScreen({super.key, required this.player});

  @override
  PlaylistScreenState createState() => PlaylistScreenState();
}

class PlaylistScreenState extends State<PlaylistScreen> {
  final PlaylistService _playlistService = PlaylistService();
  List<Map<String, dynamic>> playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final loadedPlaylists = await _playlistService.loadPlaylists();
    setState(() {
      playlists = loadedPlaylists;
    });
  }

  void _createPlaylist(String name) async {
    await _playlistService.createPlaylist(name);
    _loadPlaylists();
  }

  void _deletePlaylist(int index) async {
    final updatedPlaylists = List<Map<String, dynamic>>.from(playlists);
    updatedPlaylists.removeAt(index);
    await _playlistService.savePlaylists(updatedPlaylists);
    _loadPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Playlists',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        itemCount: playlists.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return ListTile(
              leading: const Icon(Icons.add, color: Colors.white),
              title: const Text('Create New Playlist',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreatePlaylistScreen(
                      onPlaylistCreated: _createPlaylist,
                    ),
                  ),
                );
              },
            );
          } else {
            final playlist = playlists[index - 1];
            return Dismissible(
              key: Key(playlist['name']),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                _deletePlaylist(index - 1);
              },
              child: ListTile(
                title: Text(playlist['name'],
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text('${playlist['songs'].length} songs',
                    style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaylistSongsScreen(
                        playlist: playlist,
                        player: widget.player,
                        onPlaylistUpdated: _loadPlaylists,
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}

class CreatePlaylistScreen extends StatelessWidget {
  final Function(String) onPlaylistCreated;

  CreatePlaylistScreen({Key? key, required this.onPlaylistCreated}) : super(key: key);

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Playlist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  onPlaylistCreated(_controller.text);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}