import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../services/audio_service.dart';
import '../services/playlist_service.dart';
import '../utils/utils.dart';

class PlaylistSongsScreen extends StatefulWidget {
  final Map<String, dynamic> playlist;
  final VoidCallback onPlaylistUpdated;

  const PlaylistSongsScreen({
    super.key,
    required this.playlist,
    required this.onPlaylistUpdated,
  });

  @override
  PlaylistSongsScreenState createState() => PlaylistSongsScreenState();
}

class PlaylistSongsScreenState extends State<PlaylistSongsScreen>
    with SingleTickerProviderStateMixin {
  final PlaylistService _playlistService = PlaylistService();
  final AudioService _audioService = AudioService();
  List<Map<String, dynamic>> _allSongs = [];
  Set<String> _selectedSongIds = {};
  SongModel? displayedSong;
  bool isPlaying = false;
  Color labelColor = Colors.white;
  Color unselectedLabelColor = Colors.grey;
  Color indicatorColor = Colors.white;
  late final AnimationController _animationController;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _loadAllSongs();
    _selectedSongIds = Set<String>.from(
        widget.playlist['songs'].map((song) => song['id'].toString()));

    _audioService.player.isPlaying.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = event;
        });
      }
    });

    _audioService.player.current.listen((playingAudio) {
      if (playingAudio != null) {
        _updateCurrentSongInfo();
      }
    });
  }

  void _updateCurrentSongInfo() {
    final currentAudio = _audioService.player.current.value?.audio;
    if (currentAudio != null) {
      final songId = int.tryParse(currentAudio.audio.metas.id ?? '0');
      if (songId != null) {
        final song = widget.playlist['songs'].firstWhere(
          (song) => song['id'] == songId,
          orElse: () => {
            'id': 0,
            'title': 'Unknown Title',
            'artist': 'Unknown Artist',
            'album': 'Unknown Album',
            'data': '',
          },
        );

        setState(() {
          displayedSong = SongModel({
            'id': song['id'] ?? 0,
            'title': song['title'] ?? 'Unknown Title',
            'artist': song['artist'] ?? 'Unknown Artist',
            'album': song['album'] ?? 'Unknown Album',
            'data': song['data'] ?? '',
          });
          _updateColors();
        });
      }
    }
  }

  Future<void> _loadAllSongs() async {
    final OnAudioQuery audioQuery = OnAudioQuery();
    final songs = await audioQuery.querySongs();
    setState(() {
      _allSongs = songs
          .map((song) => {
                'id': song.id.toString(),
                'title': song.title,
                'artist': song.artist,
                'album': song.album,
                'data': song.data,
              })
          .toList();
    });
  }

  void _updateColors() async {
    final colors = await getImageColors(_audioService.player);
    setState(() {
      labelColor = colors.lightMutedColor?.color ?? Colors.white;
      indicatorColor = colors.lightMutedColor?.color ?? Colors.white;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.playlist['name'],
            style: const TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          Column(
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
                      : const Icon(Icons.add_photo_alternate,
                          size: 50, color: Colors.white),
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
                      onPressed: _showAddSongsDialog,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play All'),
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
                child: _buildSongsList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    if (widget.playlist['songs'].isEmpty) {
      return const Center(child: Text('No songs in this playlist'));
    }
    return ReorderableListView.builder(
      itemCount: widget.playlist['songs'].length,
      itemBuilder: (context, index) {
        final song = widget.playlist['songs'][index];
        return Dismissible(
          key: ValueKey('${song['id']}_$index'),
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
            key: ValueKey('tile_${song['id']}_$index'),
            leading: QueryArtworkWidget(
              id: int.parse(song['id'].toString()),
              type: ArtworkType.AUDIO,
              nullArtworkWidget: const Icon(Icons.music_note),
            ),
            title: Text(song['title'] ?? 'Unknown Title'),
            subtitle: Text(song['artist'] ?? 'Unknown Artist'),
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
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        widget.playlist['image'] = pickedFile.path;
      });
      await _playlistService.updatePlaylistImage(
          widget.playlist['name'], pickedFile.path);
      widget.onPlaylistUpdated();
    }
  }

  void _playSong(int index) {
    final List<SongModel> playlistSongs = widget.playlist['songs']
        .where((song) => song['data'] != null && song['data'].isNotEmpty)
        .map((song) => SongModel({
              'id': int.tryParse(song['id']?.toString() ?? '') ?? 0,
              'title': song['title'] ?? 'Unknown Title',
              'artist': song['artist'] ?? 'Unknown Artist',
              'album': song['album'] ?? 'Unknown Album',
              'data': song['data'],
            }))
        .toList()
        .cast<SongModel>();

    if (playlistSongs.isNotEmpty &&
        index >= 0 &&
        index < playlistSongs.length) {
      _audioService.player.pause().then((_) {
        _audioService.playPlaylist(playlistSongs, index).then((_) {
          setState(() {
            displayedSong = playlistSongs[index];
            _updateColors();
          });
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to play the selected song')),
      );
    }
  }

  void _playAllSongs() {
    final List<SongModel> playlistSongs = widget.playlist['songs']
        .where((song) => song['data'] != null && song['data'].isNotEmpty)
        .map((song) => SongModel({
              'id': int.tryParse(song['id']?.toString() ?? '') ?? 0,
              'title': song['title'] ?? 'Unknown Title',
              'artist': song['artist'] ?? 'Unknown Artist',
              'album': song['album'] ?? 'Unknown Album',
              'data': song['data'],
            }))
        .toList()
        .cast<SongModel>();

    if (playlistSongs.isNotEmpty) {
      _audioService.playPlaylist(playlistSongs, 0).then((_) {
        setState(() {
          displayedSong = playlistSongs[0];
          _updateColors();
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid songs found in the playlist')),
      );
    }
  }

  void _removeSongFromPlaylist(int index) async {
    final song = widget.playlist['songs'][index];
    await _playlistService.removeSongFromPlaylist(widget.playlist, song);
    setState(() {
      widget.playlist['songs'].removeAt(index);
      _selectedSongIds.remove(song['id'].toString());
    });
    widget.onPlaylistUpdated();
  }

  Future<void> _savePlaylist() async {
    final playlists = await _playlistService.loadPlaylists();
    final index =
        playlists.indexWhere((p) => p['name'] == widget.playlist['name']);
    if (index != -1) {
      playlists[index] = widget.playlist;
      await _playlistService.savePlaylists(playlists);
      widget.onPlaylistUpdated();
    }
  }

  void _showAddSongsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Add Songs to ${widget.playlist['name']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: _allSongs.length,
                          itemBuilder: (context, index) {
                            final song = _allSongs[index];
                            final bool isSelected =
                                _selectedSongIds.contains(song['id']);
                            return CheckboxListTile(
                              title: Text(song['title'] ?? 'Unknown Title'),
                              subtitle:
                                  Text(song['artist'] ?? 'Unknown Artist'),
                              secondary: QueryArtworkWidget(
                                id: int.parse(song['id']),
                                type: ArtworkType.AUDIO,
                                nullArtworkWidget: const Icon(Icons.music_note),
                              ),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedSongIds.add(song['id']);
                                    _addSongToPlaylist(song);
                                  } else {
                                    _selectedSongIds.remove(song['id']);
                                    _removeSongFromPlaylist(
                                        widget.playlist['songs'].indexWhere(
                                            (s) => s['id'] == song['id']));
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      child: const Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addSongToPlaylist(Map<String, dynamic> song) async {
    await _playlistService.addSongToPlaylist(widget.playlist, song);
    setState(() {
      widget.playlist['songs'].add(song);
    });
    widget.onPlaylistUpdated();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
