import 'dart:io';
import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:musicify/services/playlist_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:image_picker/image_picker.dart';


class PlaylistSongsScreen extends StatefulWidget {
  final Map<String, dynamic> playlist;
  final AssetsAudioPlayer player;
  final VoidCallback onPlaylistUpdated;

  const PlaylistSongsScreen({
    super.key,
    required this.playlist,
    required this.player,
    required this.onPlaylistUpdated,
  });

  @override
  PlaylistSongsScreenState createState() => PlaylistSongsScreenState();
}

class PlaylistSongsScreenState extends State<PlaylistSongsScreen> {
  final PlaylistService _playlistService = PlaylistService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.playlist['name'], style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: widget.playlist['image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(widget.playlist['image']),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate, size: 50, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add to playlist'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    // Implement add songs to playlist functionality
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _playAllSongs,
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: widget.playlist['songs'].length,
              itemBuilder: (context, index) {
                final song = widget.playlist['songs'][index];
                return Dismissible(
                  key: Key(song['id'].toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _removeSongFromPlaylist(index);
                  },
                  child: ListTile(
                    leading: QueryArtworkWidget(
                      id: int.parse(song['id']),
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: const Icon(Icons.music_note),
                    ),
                    title: Text(song['title'],
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(song['artist'],
                        style: const TextStyle(color: Colors.white70)),
                    onTap: () => _playSong(index),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = widget.playlist['songs'].removeAt(oldIndex);
                  widget.playlist['songs'].insert(newIndex, item);
                });
                _savePlaylist();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        widget.playlist['image'] = pickedFile.path;
      });
      await _playlistService.updatePlaylistImage(widget.playlist['name'], pickedFile.path);
      widget.onPlaylistUpdated();
    }
  }

  void _playAllSongs() {
    final playlist = Playlist(
      audios: widget.playlist['songs']
          .map<Audio>((song) => Audio.file(
                song['data'],
                metas: Metas(
                  id: song['id'].toString(),
                  title: song['title'],
                  artist: song['artist'],
                ),
              ))
          .toList(),
    );
    widget.player.open(playlist, autoStart: true);
  }

  void _playSong(int index) {
    final playlist = Playlist(
      audios: widget.playlist['songs']
          .map<Audio>((song) => Audio.file(
                song['data'],
                metas: Metas(
                  id: song['id'].toString(),
                  title: song['title'],
                  artist: song['artist'],
                ),
              ))
          .toList(),
    );
    widget.player.open(playlist, autoStart: true, loopMode: LoopMode.playlist);
    widget.player.playlistPlayAtIndex(index);
  }

  void _removeSongFromPlaylist(int index) async {
    final song = widget.playlist['songs'][index];
    await _playlistService.removeSongFromPlaylist(widget.playlist, song);
    setState(() {
      widget.playlist['songs'].removeAt(index);
    });
    widget.onPlaylistUpdated();
  }

  Future<void> _savePlaylist() async {
    final playlists = await _playlistService.loadPlaylists();
    final index = playlists.indexWhere((p) => p['name'] == widget.playlist['name']);
    if (index != -1) {
      playlists[index] = widget.playlist;
      await _playlistService.savePlaylists(playlists);
      widget.onPlaylistUpdated();
    }
  }
}