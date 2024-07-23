import 'dart:math' as math;
import 'dart:ui';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../screens/player_screen.dart';
import '../screens/search_screen.dart';
import '../services/audio_service.dart';
import '../utils/audio_state.dart';
import '../utils/utils.dart';
import '../widgets/album_grid_item.dart';
import '../widgets/artist_list_item.dart';
import '../widgets/song_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  bool isPlaying = false;
  List<SongModel> _songs = [];
  List<ArtistModel> _artists = [];
  List<AlbumModel> _albums = [];
  SongModel? displayedSong;
  Color labelColor = Colors.white;
  Color unselectedLabelColor = Colors.grey;
  Color indicatorColor = Colors.white;
  int? currentSongIndex;

  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _initialize();
    _audioService.player.currentPosition.listen((position) {
      // Handle position changes if needed
    });

    _audioService.player.playlistAudioFinished.listen((_) {
      _updateCurrentSongInfo();
    });

    _audioService.player.current.listen((playingAudio) {
      if (playingAudio != null) {
        _updateCurrentSongInfo();
      }
    });

    AudioState().audioStateStream.listen((_) {
      _updateCurrentSongInfo();
    });
  }

  void _updateCurrentSongInfo() {
    final currentAudio = _audioService.player.current.value?.audio;
    if (currentAudio != null) {
      final songId = int.tryParse(currentAudio.audio.metas.id ?? '0');
      if (songId != null) {
        final song = _songs.firstWhere(
          (song) => song.id == songId,
          orElse: () => SongModel({
            'id': 0,
            'title': 'Unknown Title',
            'artist': 'Unknown Artist',
            'album': 'Unknown Album',
            'data': '',
          }),
        );

        setState(() {
          displayedSong = song;
          currentSongIndex = _songs.indexWhere((s) => s.id == song.id);
          _updateColors();
        });
      }
    }
  }

  Future<void> _initialize() async {
    try {
      if (await _audioService.requestPermission()) {
        await _fetchSongs();
      } else {
        _showPermissionDeniedDialog();
      }

      _audioService.player.isPlaying.listen((event) {
        if (mounted) {
          setState(() {
            isPlaying = event;
          });
        }
      });
    } catch (e) {
      debugPrint('Error during initialization: $e');
      _showErrorDialog('Initialization Error', e.toString());
    }
  }

  Future<void> _fetchSongs() async {
    try {
      _songs = await _audioService.fetchSongs();
      _artists = await _audioService.fetchArtists();
      _albums = await _audioService.fetchAlbums();

      setState(() {});
      if (_songs.isNotEmpty) {
        _openPlayer();
      } else {
        _showImportDialog();
      }
    } catch (e) {
      debugPrint('Error fetching songs, artists, or albums: $e');
      _showErrorDialog('Fetch Error', e.toString());
    }
  }

  void _openPlayer() async {
    await _audioService.openPlayer(_songs);
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No songs found'),
          content: const Text(
              'Would you like to import songs or use preloaded songs?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Import'),
              onPressed: () {
                Navigator.of(context).pop();
                _importSongs();
              },
            ),
            TextButton(
              child: const Text('Use preloaded'),
              onPressed: () {
                Navigator.of(context).pop();
                _openPlayer();
              },
            ),
          ],
        );
      },
    );
  }

  void _importSongs() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      List<Audio> importedSongs = result.files.map((file) {
        return Audio.file(file.path!,
            metas: Metas(
              title: file.name,
              artist: 'Unknown Artist',
              album: 'Unknown Album',
              image: MetasImage.file(file.path!),
            ));
      }).toList();

      setState(() {
        _songs = importedSongs
            .map((audio) => SongModel({
                  'id': audio.path.hashCode,
                  'title': audio.metas.title ?? '',
                  'artist': audio.metas.artist ?? 'Unknown Artist',
                  'album': audio.metas.album ?? 'Unknown Album',
                  'data': audio.path,
                }))
            .toList();
      });

      _openPlayer();
    }
  }

  void _updateColors() async {
    final colors = await getImageColors(_audioService.player);
    setState(() {
      labelColor = colors.lightMutedColor?.color ?? Colors.white;
      indicatorColor = colors.lightMutedColor?.color ?? Colors.white;
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
            'Audio permission was denied. The app cannot access your audio files.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity! > 0) {
      _playPreviousSong();
    } else if (details.primaryVelocity! < 0) {
      _playNextSong();
    }
  }

  void _playPreviousSong() {
    _audioService.player.currentPosition.first.then((position) {
      if (position > const Duration(seconds: 3)) {
        _audioService.player.seek(Duration.zero);
      } else {
        _audioService.player.previous();
      }
      _updateCurrentSong();
    });
  }

  void _playNextSong() {
    _audioService.player.next().then((_) {
      _updateCurrentSongInfo();
    });
  }

  void _updateCurrentSong() async {
    final currentAudio = _audioService.player.current.value?.audio;
    if (currentAudio != null) {
      final songId = int.tryParse(currentAudio.audio.metas.id ?? '0');
      if (songId != null) {
        final songIndex = _songs.indexWhere((song) => song.id == songId);
        if (songIndex != -1 && songIndex != currentSongIndex) {
          setState(() {
            displayedSong = _songs[songIndex];
            currentSongIndex = songIndex;
          });
          _updateColors();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Playing?>(
        stream: _audioService.player.current,
        builder: (context, snapshot) {
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Musicify',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        CupertinoPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => SearchScreen(
                            player: _audioService.player,
                          ),
                        ),
                      );
                      if (result != null && result is SongModel) {
                        setState(() {
                          displayedSong = result;
                          currentSongIndex =
                              _songs.indexWhere((song) => song.id == result.id);
                        });
                        _updateColors();
                      }
                    },
                    icon:
                        const Icon(CupertinoIcons.search, color: Colors.white),
                  ),
                ],
                bottom: TabBar(
                  tabs: const [
                    Tab(
                        child: Text('Songs',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold))),
                    Tab(
                        child: Text('Artists',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold))),
                    Tab(
                        child: Text('Albums',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold))),
                  ],
                  labelColor: labelColor,
                  unselectedLabelColor: unselectedLabelColor,
                  indicatorColor: indicatorColor,
                  dividerColor: Colors.transparent,
                ),
              ),
              body: Stack(
                children: [
                  TabBarView(
                    children: [
                      _buildSongsList(),
                      _buildArtistsList(),
                      _buildAlbumsList(),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildMiniPlayer(),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildMiniPlayer() {
    return displayedSong == null
        ? const SizedBox.shrink()
        : FutureBuilder<PaletteGenerator>(
            future: getImageColors(_audioService.player),
            builder: (context, snapshot) {
              final progressColor =
                  snapshot.data?.lightMutedColor?.color ?? Colors.white;
              return GestureDetector(
                onHorizontalDragEnd: (details) => _handleSwipe(details),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  height: 75,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: const Alignment(0, 5),
                      colors: [
                        (snapshot.data?.lightMutedColor?.color ?? Colors.grey)
                            .withOpacity(0.8),
                        (snapshot.data?.mutedColor?.color ?? Colors.grey)
                            .withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                        child: Stack(
                          children: [
                            ListTile(
                              leading: AnimatedBuilder(
                                animation: _animationController,
                                builder: (_, child) {
                                  if (!isPlaying) {
                                    _animationController.stop();
                                  } else {
                                    _animationController.forward();
                                    _animationController.repeat();
                                  }
                                  return Transform.rotate(
                                    angle: _animationController.value *
                                        2 *
                                        math.pi,
                                    child: child,
                                  );
                                },
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: QueryArtworkWidget(
                                      id: displayedSong!.id,
                                      type: ArtworkType.AUDIO,
                                      artworkBorder: BorderRadius.circular(30),
                                      nullArtworkWidget: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey,
                                        ),
                                        child: const Icon(Icons.music_note,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) => PlayerScreen(
                                      player: _audioService.player,
                                    ),
                                  ),
                                );
                              },
                              title: Text(
                                displayedSong!.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                displayedSong!.artist ?? 'Unknown Artist',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      await _audioService.player.playOrPause();
                                    },
                                    icon: Icon(
                                      isPlaying
                                          ? CupertinoIcons.pause
                                          : CupertinoIcons.play_arrow,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await _audioService.player.next();
                                      _updateCurrentSong();
                                    },
                                    icon: const Icon(
                                      CupertinoIcons.forward_end,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: StreamBuilder<Duration>(
                                stream: _audioService.player.currentPosition,
                                builder: (context, snapshot) {
                                  final position =
                                      snapshot.data ?? Duration.zero;
                                  final duration = _audioService.player.current
                                          .value?.audio.duration ??
                                      Duration.zero;
                                  final progress = duration.inMilliseconds > 0
                                      ? position.inMilliseconds /
                                          duration.inMilliseconds
                                      : 0.0;
                                  return ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(20)),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor:
                                          progressColor.withOpacity(.1),
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                          Colors.grey),
                                      minHeight: 3,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildSongsList() {
    if (_songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      separatorBuilder: (context, index) {
        return const Divider(
          color: Colors.white30,
          height: 0,
          thickness: 1,
          indent: 85,
        );
      },
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        return SongListItem(
          song: _songs[index],
          onTap: () async {
            await _audioService.player.stop();
            List<Audio> playlist = _songs
                .sublist(index)
                .map((song) => Audio.file(
                      song.data,
                      metas: Metas(
                        id: song.id.toString(),
                        title: song.title,
                        artist: song.artist,
                        album: song.album,
                      ),
                    ))
                .toList();
            await _audioService.player.open(
              Playlist(audios: playlist),
              showNotification: true,
            );
            setState(() {
              displayedSong = _songs[index];
              currentSongIndex = index;
            });
            _updateColors();
          },
          player: _audioService.player,
          isSelected: index == currentSongIndex,
        );
      },
    );
  }

  Widget _buildArtistsList() {
    return ListView.builder(
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        return ArtistListItem(
          artist: _artists[index],
          songs: _songs
              .where((song) => song.artist == _artists[index].artist)
              .toList(),
          player: _audioService.player,
        );
      },
    );
  }

  Widget _buildAlbumsList() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        return AlbumGridItem(
          album: _albums[index],
          player: _audioService.player,
          songs: _songs
              .where((song) => song.album == _albums[index].album)
              .toList(),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
