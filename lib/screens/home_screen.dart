import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:musicify/screens/search_screen.dart';
import 'package:musicify/utils/utils.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomeScreen extends StatefulWidget {
  final AssetsAudioPlayer player;
  const HomeScreen({super.key, required this.player});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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

    widget.player.isPlaying.listen((event) {
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
      await widget.player.open(playlist,
          autoStart: false,
          showNotification: true,
          loopMode: LoopMode.playlist);
    } else {
      openPlayer();
    }
  }

  void openPlayer() async {
    await widget.player.open(Playlist(audios: songs),
        autoStart: false, showNotification: true, loopMode: LoopMode.playlist);
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
                        builder: (context) => const SearchScreen()));
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: FutureBuilder<PaletteGenerator>(
              future: getImageColors(widget.player),
              builder: (context, snapshot) {
                final selectedColor =
                    snapshot.data?.lightMutedColor?.color ?? Colors.white;
                return TabBar(
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
                  labelColor: selectedColor,
                  unselectedLabelColor: Colors.white,
                  indicatorColor: selectedColor,
                  dividerColor: Colors.transparent,
                );
              },
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildSongsList(),
            _buildArtistsList(),
            _buildAlbumsList(),
          ],
        ),
      ),
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
                  ? const Icon(CupertinoIcons.music_note, color: Colors.white)
                  : Image.asset((song as Audio).metas.image!.path),
            ),
            onTap: () async {
              if (isImportedSong) {
                await widget.player.open(
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
                await widget.player.playlistPlayAtIndex(index);
              }
              setState(() {
                widget.player.getCurrentAudioImage;
                widget.player.getCurrentAudioTitle;
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
        final artistSongs =
            _songs.where((song) => song.artist == artist.artist).toList();
        return ExpansionTile(
          title:
              Text(artist.artist, style: const TextStyle(color: Colors.white)),
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: artistSongs.length,
              itemBuilder: (context, songIndex) {
                final song = artistSongs[songIndex];
                return ListTile(
                  title: Text(song.title,
                      style: const TextStyle(color: Colors.white)),
                  onTap: () async {
                    await widget.player.open(
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
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumsList() {
    return ListView.builder(
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        final albumSongs =
            _songs.where((song) => song.album == album.album).toList();
        return ExpansionTile(
          title: Text(album.album, style: const TextStyle(color: Colors.white)),
          subtitle: Text(album.artist ?? 'Unknown Artist',
              style: const TextStyle(color: Colors.white70)),
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: albumSongs.length,
              itemBuilder: (context, songIndex) {
                final song = albumSongs[songIndex];
                return ListTile(
                  title: Text(song.title,
                      style: const TextStyle(color: Colors.white)),
                  onTap: () async {
                    await widget.player.open(
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
                );
              },
            ),
          ],
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
