import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:musicify/screens/search_screen.dart';
import 'package:musicify/screens/player_screen.dart';
import 'package:musicify/widgets/song_list_item.dart';
import 'package:musicify/widgets/artist_list_item.dart';
import 'package:musicify/widgets/album_grid_item.dart';
import 'package:musicify/utils/utils.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  final AssetsAudioPlayer player;
  final Function(SongModel) onSongSelected;
  const HomeScreen(
      {super.key, required this.player, required this.onSongSelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  List<ArtistModel> _artists = [];
  List<AlbumModel> _albums = [];
  SongModel? displayedSong;
  Color labelColor = Colors.white;
  Color unselectedLabelColor = Colors.grey;
  Color indicatorColor = Colors.white;

  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _openPlayer();

    widget.player.isPlaying.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = event;
        });
      }
    });

    widget.player.current.listen((playingAudio) {
      // if (playingAudio != null && playingAudio.audio.audio.path != null) {
      if (playingAudio != null) {
        _updateDisplayedSong(SongModel({
          'id': playingAudio.audio.audio.metas.id,
          'title': playingAudio.audio.audio.metas.title ?? 'Unknown Title',
          'artist': playingAudio.audio.audio.metas.artist ?? 'Unknown Artist',
          'album': playingAudio.audio.audio.metas.album ?? 'Unknown Album',
          'data': playingAudio.audio.audio.path,
        }));
        _updateColors();
      }
    });
  }

  void _requestPermission() async {
    if (await Permission.storage.request().isGranted) {
      _fetchSongs();
    } else {
      _openPlayer();
    }
  }

  void _fetchSongs() async {
    _songs = await _audioQuery.querySongs(
      ignoreCase: true,
      orderType: OrderType.ASC_OR_SMALLER,
      sortType: null,
      uriType: UriType.EXTERNAL,
    );
    _artists = await _audioQuery.queryArtists();
    _albums = await _audioQuery.queryAlbums();
    setState(() {});
    _openPlayer();
  }

  void _openPlayer() async {
    if (_songs.isNotEmpty) {
      final playlist = Playlist(
        audios: _songs
            .map((song) => Audio.file(song.data,
                metas: Metas(
                  title: song.title,
                  artist: song.artist,
                  album: song.album,
                  image: MetasImage.file(song.data),
                )))
            .toList(),
      );
      await widget.player.open(playlist,
          autoStart: false,
          showNotification: true,
          loopMode: LoopMode.playlist);
    } else {
      _showImportDialog();
    }
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

  void _updateDisplayedSong(SongModel song) {
    if (song.data != null) {
      setState(() {
        displayedSong = song;
      });
      widget.onSongSelected(song);
      widget.player.open(
        Audio.file(
          song.data,
          metas: Metas(
            id: song.id.toString(),
            title: song.title,
            artist: song.artist,
            album: song.album,
            image: MetasImage.file(song.data),
          ),
        ),
        showNotification: true,
      );
    }
  }

  void _updateColors() async {
    final colors = await getImageColors(widget.player);
    setState(() {
      labelColor = colors.lightMutedColor?.color ?? Colors.white;
      indicatorColor = colors.lightMutedColor?.color ?? Colors.white;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Musicify',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.search, color: Colors.white),
              onPressed: () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => SearchScreen(
                              player: widget.player,
                              onSongSelected: widget.onSongSelected,
                            )));
              },
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
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildSongsList(),
                  _buildArtistsList(),
                  _buildAlbumsList(),
                ],
              ),
            ),
            _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return displayedSong == null
        ? const SizedBox.shrink()
        : FutureBuilder<PaletteGenerator>(
            future: getImageColors(widget.player),
            builder: (context, snapshot) {
              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                height: 75,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: const Alignment(0, 5),
                        colors: [
                          snapshot.data?.lightMutedColor?.color ?? Colors.grey,
                          snapshot.data?.mutedColor?.color ?? Colors.grey,
                        ]),
                    borderRadius: BorderRadius.circular(20)),
                child: ListTile(
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
                          angle: _animationController.value * 2 * math.pi,
                          child: child);
                    },
                    child: ClipOval(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: QueryArtworkWidget(
                          id: displayedSong?.id ?? 0,
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
                    if (displayedSong != null) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => PlayerScreen(
                            player: widget.player,
                          ),
                        ),
                      );
                    }
                  },
                  title: Text(
                    displayedSong?.title ?? 'No song',
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    displayedSong?.artist ?? 'Unknown Artist',
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          if (displayedSong != null) {
                            await widget.player.playOrPause();
                          }
                        },
                        icon: isPlaying
                            ? const Icon(CupertinoIcons.pause)
                            : const Icon(CupertinoIcons.play_arrow),
                      ),
                      IconButton(
                        onPressed: () async {
                          await widget.player.next();
                        },
                        icon: const Icon(
                          CupertinoIcons.forward_end,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildSongsList() {
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
          player: widget.player,
          onTap: () {
            _updateDisplayedSong(_songs[index]);
          },
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
          player: widget.player,
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
          songs: _songs
              .where((song) => song.album == _albums[index].album)
              .toList(),
          player: widget.player,
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
