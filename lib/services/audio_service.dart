import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AssetsAudioPlayer player = AssetsAudioPlayer.newPlayer();

  Future<bool> requestPermission() async {
    if (await Permission.audio.request().isGranted) {
      return true;
    }
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    // For Android 13+
    if (await Permission.photos.request().isGranted) {
      return true;
    }
    return false;
  }

  Future<List<SongModel>> fetchSongs() async {
    return await _audioQuery.querySongs(
      ignoreCase: true,
      orderType: OrderType.ASC_OR_SMALLER,
      sortType: null,
      uriType: UriType.EXTERNAL,
    );
  }

  Future<List<ArtistModel>> fetchArtists() async {
    return await _audioQuery.queryArtists();
  }

  Future<List<AlbumModel>> fetchAlbums() async {
    return await _audioQuery.queryAlbums();
  }

  Future<void> openPlayer(List<SongModel> songs) async {
    if (songs.isNotEmpty) {
      final playlist = Playlist(
        audios: songs
            .map((song) => Audio.file(
                  song.data!,
                  metas: Metas(
                    id: song.id.toString(),
                    title: song.title,
                    artist: song.artist,
                    album: song.album,
                    image: MetasImage.file(song.data!),
                  ),
                ))
            .toList(),
      );
      await player.open(
        playlist,
        autoStart: false,
        showNotification: true,
        loopMode: LoopMode.playlist,
      );
    }
  }

  void shufflePlaylist() {
    final currentPlaylist = player.playlist?.audios;
    if (currentPlaylist != null && currentPlaylist.isNotEmpty) {
      final shuffledAudios = List<Audio>.from(currentPlaylist)..shuffle();
      player.stop();
      player.open(
        Playlist(audios: shuffledAudios),
        autoStart: true,
      );
    }
  }

  Future<void> playSong(SongModel song) async {
    await player.stop();
    await player.open(
      Audio.file(
        song.data!,
        metas: Metas(
          id: song.id.toString(),
          title: song.title,
          artist: song.artist,
          album: song.album,
          image: MetasImage.file(song.data!),
        ),
      ),
      showNotification: true,
    );
    player.play();
  }

  Future<void> playPlaylist(List<SongModel> songs, int initialIndex) async {
    await player.stop();
    final playlist = Playlist(
      audios: songs
          .map((song) => Audio.file(
                song.data!,
                metas: Metas(
                  id: song.id.toString(),
                  title: song.title,
                  artist: song.artist,
                  album: song.album,
                  image: MetasImage.file(song.data!),
                ),
              ))
          .toList(),
    );
    await player.open(
      playlist,
      autoStart: true,
      showNotification: true,
      loopMode: LoopMode.playlist,
    );
    player.playlistPlayAtIndex(initialIndex);
  }
}