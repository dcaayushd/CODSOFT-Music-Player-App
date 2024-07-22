import 'dart:async';

import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

import 'package:musicify/services/audio_service.dart';
import 'package:musicify/services/playlist_service.dart';

import 'package:musicify/utils/audio_state.dart';
import 'package:musicify/utils/utils.dart';

import '../services/favorites_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required AssetsAudioPlayer player});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final PlaylistService _playlistService = PlaylistService();
  final FavoritesService _favoritesService = FavoritesService();
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isPlaying = true;
  bool isFavorite = false;
  String? currentArtworkId;
  String? currentTitle;

  late final ScrollController _titleScrollController;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _titleScrollController = ScrollController();

    _audioService.player.isPlaying.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = event;
        });
      }
    });
    _audioService.player.onReadyToPlay.listen((newDuration) {
      if (mounted) {
        setState(() {
          duration = newDuration?.duration ?? Duration.zero;
        });
      }
    });

    _audioService.player.currentPosition.listen((newPosition) {
      if (mounted) {
        setState(() {
          position = newPosition;
        });
      }
    });

    _audioService.player.playlistAudioFinished.listen((finished) {
      if (finished == true) {
        _audioService.player.next();
      }
    });

    _audioService.player.current.listen((playingAudio) {
      if (mounted) {
        setState(() {
          currentArtworkId =
              _audioService.player.current.value?.audio.audio.metas.id;
          currentTitle = _audioService.player.getCurrentAudioTitle;
          _startScrollingTitle();
        });
        AudioState().notifyAudioStateChanged();
      }
    });
    _audioService.player.playlistAudioFinished.listen((finished) {
      if (finished == true) {
        _audioService.player.next();
        AudioState().notifyAudioStateChanged();
      }
    });

    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final favorites = await _favoritesService.getFavorites();
    final currentSongId =
        _audioService.player.current.value?.audio.audio.metas.id;
    setState(() {
      isFavorite = favorites.any((favorite) => favorite['id'] == currentSongId);
    });
  }

  void _toggleFavorite() async {
    final currentSong = {
      'id': _audioService.player.current.value?.audio.audio.metas.id,
      'title': _audioService.player.getCurrentAudioTitle,
      'artist': _audioService.player.getCurrentAudioArtist,
      'artworkId': currentArtworkId,
    };

    if (isFavorite) {
      await _favoritesService.removeFavorite(currentSong['id'] as String);
    } else {
      await _favoritesService.addFavorite(currentSong);
    }

    setState(() {
      isFavorite = !isFavorite;
    });
  }

  void _startScrollingTitle() {
    if (currentTitle == null) return;

    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_titleScrollController.hasClients) {
        double maxScrollExtent =
            _titleScrollController.position.maxScrollExtent;
        if (_titleScrollController.offset >= maxScrollExtent) {
          _titleScrollController.jumpTo(0);
        } else {
          _titleScrollController.animateTo(
            _titleScrollController.offset + 1,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  Future<void> _showPlaylistOptions() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add to Playlist"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showExistingPlaylists();
                },
                child: const Text("Add to Existing Playlist"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog();
                },
                child: const Text("Create New Playlist"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showExistingPlaylists() async {
    final playlists = await _playlistService.loadPlaylists();

    final currentSong = {
      'id': _audioService.player.current.value?.audio.audio.metas.id,
      'title': _audioService.player.getCurrentAudioTitle,
      'artist': _audioService.player.getCurrentAudioArtist,
      'data': _audioService.player.current.value?.audio.audio.path,
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Playlist"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                final isInPlaylist = playlist['songs']
                    .any((song) => song['id'] == currentSong['id']);
                return CheckboxListTile(
                  title: Text(playlist['name']),
                  value: isInPlaylist,
                  onChanged: (bool? value) {
                    if (value == true) {
                      _addSongToPlaylist(playlist, currentSong);
                    } else {
                      _removeSongFromPlaylist(playlist, currentSong);
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreatePlaylistDialog() async {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create New Playlist"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter playlist name"),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Create"),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _createPlaylist(controller.text);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createPlaylist(String name) async {
    await _playlistService.createPlaylist(name);

    final currentSong = {
      'id': _audioService.player.current.value?.audio.audio.metas.id,
      'title': _audioService.player.getCurrentAudioTitle,
      'artist': _audioService.player.getCurrentAudioArtist,
      'data': _audioService.player.current.value?.audio.audio.path,
    };

    final newPlaylist = {'name': name, 'songs': []};
    await _playlistService.addSongToPlaylist(newPlaylist, currentSong);
  }

  Future<void> _addSongToPlaylist(
      Map<String, dynamic> playlist, Map<String, dynamic> song) async {
    await _playlistService.addSongToPlaylist(playlist, song);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to ${playlist['name']}')),
    );
  }

  Future<void> _removeSongFromPlaylist(
      Map<String, dynamic> playlist, Map<String, dynamic> song) async {
    await _playlistService.removeSongFromPlaylist(playlist, song);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed from ${playlist['name']}')),
    );
  }

  void _shufflePlaylist() {
    _audioService.shufflePlaylist();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _titleScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 30,
                color: Colors.white,
              )),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          FutureBuilder<PaletteGenerator>(
            future: getImageColors(_audioService.player),
            builder: (context, snapshot) {
              return Container(
                color: snapshot.data?.mutedColor?.color ?? Colors.black,
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(.7)
                  ])),
            ),
          ),
          Positioned(
            height: MediaQuery.of(context).size.height / 1.5,
            child: Column(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 30,
                  child: currentTitle != null &&
                          currentTitle!.split(' ').length > 3
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _titleScrollController,
                          child: Row(
                            children: [
                              Text(
                                currentTitle!,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4),
                              Text(
                                currentTitle!,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          currentTitle ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  _audioService.player.getCurrentAudioArtist,
                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 20,
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Text(
                        durationFormat(position),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const VerticalDivider(
                        color: Colors.white54,
                        thickness: 2,
                        width: 25,
                        indent: 2,
                        endIndent: 2,
                      ),
                      Text(
                        durationFormat(duration - position),
                        style: const TextStyle(color: Colors.red),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: SleekCircularSlider(
              min: 0,
              max: duration.inSeconds.toDouble(),
              initialValue: position.inSeconds.toDouble(),
              onChange: (value) async {
                await _audioService.player
                    .seek(Duration(seconds: value.toInt()));
              },
              innerWidget: (percentage) {
                return Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: ClipOval(
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: QueryArtworkWidget(
                        id: int.tryParse(currentArtworkId ?? '0') ?? 0,
                        type: ArtworkType.AUDIO,
                        artworkBorder: BorderRadius.circular(140),
                        nullArtworkWidget: Container(
                          width: 280,
                          height: 280,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                          child: const Icon(Icons.music_note,
                              color: Colors.white, size: 140),
                        ),
                      ),
                    ),
                  ),
                );
              },
              appearance: CircularSliderAppearance(
                size: 330,
                angleRange: 300,
                startAngle: 300,
                customColors: CustomSliderColors(
                  progressBarColor: Colors.red,
                  dotColor: Colors.red,
                  trackColor: Colors.grey.withOpacity(.4),
                ),
                customWidths: CustomSliderWidths(
                  trackWidth: 6,
                  handlerSize: 10,
                  progressBarWidth: 6,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 1.3,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () async {
                        await _audioService.player.previous();
                        setState(() {
                          currentArtworkId = _audioService
                              .player.current.value?.audio.audio.metas.id;
                        });
                      },
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _audioService.player.playOrPause();
                      },
                      padding: EdgeInsets.zero,
                      icon: isPlaying
                          ? const Icon(
                              Icons.pause_circle,
                              size: 70,
                              color: Colors.white,
                            )
                          : const Icon(
                              Icons.play_circle,
                              size: 70,
                              color: Colors.white,
                            ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _audioService.player.next();
                        setState(() {
                          currentArtworkId = _audioService
                              .player.current.value?.audio.audio.metas.id;
                        });
                        // Notify about the change
                        AudioState().notifyAudioStateChanged();
                      },
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: _shufflePlaylist,
                      icon: const Icon(
                        Icons.shuffle,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: _showPlaylistOptions,
                      icon: const Icon(
                        Icons.playlist_add,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
