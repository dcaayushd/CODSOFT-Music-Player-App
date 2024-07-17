import 'dart:math' as math;
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:musicify/screens/player_screen.dart';
import 'package:musicify/utils/utils.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final player = AssetsAudioPlayer();
  bool isPlaying = true;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  List<ArtistModel> _artists = [];
  List<AlbumModel> _albums = [];

  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _requestPermission();
    openPlayer();

    player.isPlaying.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = event;
        });
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
    _songs = await _audioQuery.querySongs();
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
                )))
            .toList(),
      );
      await player.open(playlist,
          autoStart: false,
          showNotification: true,
          loopMode: LoopMode.playlist);
    } else {
      openPlayer();
    }
  }

  void openPlayer() async {
    await player.open(Playlist(audios: songs),
        autoStart: false, showNotification: true, loopMode: LoopMode.playlist);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.withOpacity(.2),
        appBar: AppBar(
          title: const Text(
            'Musicify',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Songs',),
              Tab(text: 'Artists'),
              Tab(text: 'Albums'),
            ],
          ),
        ),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            TabBarView(
              children: [
                _buildSongsList(),
                _buildArtistsList(),
                _buildAlbumsList(),
              ],
            ),
            player.getCurrentAudioImage == null
                ? const SizedBox.shrink()
                : FutureBuilder<PaletteGenerator>(
                    future: getImageColors(player),
                    builder: (context, snapshot) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 50),
                        height: 75,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: const Alignment(0, 5),
                                colors: [
                                  snapshot.data?.lightMutedColor?.color ??
                                      Colors.grey,
                                  snapshot.data?.mutedColor?.color ??
                                      Colors.grey,
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
                                  angle:
                                      _animationController.value * 2 * math.pi,
                                  child: child);
                            },
                            child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey,
                                backgroundImage: AssetImage(
                                    player.getCurrentAudioImage?.path ?? '')),
                          ),
                          onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  fullscreenDialog: true,
                                  builder: (context) => PlayerScreen(
                                        player: player,
                                      ))),
                          title: Text(player.getCurrentAudioTitle),
                          subtitle: Text(player.getCurrentAudioArtist),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  await player.playOrPause();
                                },
                                icon: isPlaying
                                    ? const Icon(Icons.pause)
                                    // : const Icon(Icons.play_arrow),
                                    : const Icon(CupertinoIcons.square_grid_2x2),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await player.next();
                                },
                                icon: const Icon(
                                  Icons.skip_next_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSongsList() {
  //   final songsToShow = _songs.isNotEmpty ? _songs : songs;
  //   return ListView.separated(
  //     separatorBuilder: (context, index) {
  //       return const Divider(
  //         color: Colors.white30,
  //         height: 0,
  //         thickness: 1,
  //         indent: 85,
  //       );
  //     },
  //     itemCount: songsToShow.length,
  //     itemBuilder: (context, index) {
  //       final song = songsToShow[index];
  //       return Padding(
  //         padding: const EdgeInsets.only(top: 10),
  //         child: ListTile(
  //           title: Text(
  //             song is SongModel ? song.title : song.metas.title!,
  //             style: const TextStyle(color: Colors.white),
  //           ),
  //           subtitle: Text(
  //             song is SongModel ? song.artist ?? 'Unknown Artist' : song.metas.artist!,
  //             style: const TextStyle(color: Colors.white70),
  //           ),
  //           leading: ClipRRect(
  //             borderRadius: BorderRadius.circular(10),
  //             child: song is SongModel
  //                 ? const Icon(Icons.music_note, color: Colors.white)
  //                 : Image.asset(song.metas.image!.path),
  //           ),
  //           onTap: () async {
  //             if (song is SongModel) {
  //               await player.open(
  //                 Audio.file(song.data,
  //                     metas: Metas(
  //                       title: song.title,
  //                       artist: song.artist,
  //                       album: song.album,
  //                     )),
  //                 autoStart: true,
  //                 showNotification: true,
  //               );
  //             } else {
  //               await player.playlistPlayAtIndex(index);
  //             }
  //             setState(() {
  //               player.getCurrentAudioImage;
  //               player.getCurrentAudioTitle;
  //             });
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }
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
      itemCount: _songs.isNotEmpty ? _songs.length : songs.length,
      itemBuilder: (context, index) {
        final isImportedSong = _songs.isNotEmpty;
        final song = isImportedSong ? _songs[index] : songs[index];
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ListTile(
            title: Text(
              isImportedSong
                  ? (song as SongModel).title
                  : (song as Audio).metas.title!,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              isImportedSong
                  ? (song as SongModel).artist ?? 'Unknown Artist'
                  : (song as Audio).metas.artist!,
              style: const TextStyle(color: Colors.white70),
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: isImportedSong
                  ? const Icon(Icons.music_note, color: Colors.white)
                  : Image.asset((song as Audio).metas.image!.path),
            ),
            onTap: () async {
              if (isImportedSong) {
                await player.open(
                  Audio.file((song as SongModel).data,
                      metas: Metas(
                        title: song.title,
                        artist: song.artist,
                        album: song.album,
                      )),
                  autoStart: true,
                  showNotification: true,
                );
              } else {
                await player.playlistPlayAtIndex(index);
              }
              setState(() {
                player.getCurrentAudioImage;
                player.getCurrentAudioTitle;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildArtistsList() {
    return ListView.builder(
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return ExpansionTile(
          title:
              Text(artist.artist, style: const TextStyle(color: Colors.white)),
          children: _songs
              .where((song) => song.artist == artist.artist)
              .map((song) => ListTile(
                    title: Text(song.title,
                        style: const TextStyle(color: Colors.white)),
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
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildAlbumsList() {
    return ListView.builder(
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return ExpansionTile(
          title: Text(album.album, style: const TextStyle(color: Colors.white)),
          children: _songs
              .where((song) => song.album == album.album)
              .map((song) => ListTile(
                    title: Text(song.title,
                        style: const TextStyle(color: Colors.white)),
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
                  ))
              .toList(),
        );
      },
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
