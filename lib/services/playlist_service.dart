import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistService {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  Future<List<Map<String, dynamic>>> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getString('playlists') ?? '[]';
    return List<Map<String, dynamic>>.from(json.decode(playlistsJson));
  }

  Future<void> savePlaylists(List<Map<String, dynamic>> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playlists', json.encode(playlists));
  }

  Future<void> createPlaylist(String name) async {
    final playlists = await loadPlaylists();
    playlists.add({'name': name, 'songs': [], 'image': null});
    await savePlaylists(playlists);
  }

  Future<void> addSongToPlaylist(Map<String, dynamic> playlist, Map<String, dynamic> song) async {
    final playlists = await loadPlaylists();
    final playlistIndex = playlists.indexWhere((p) => p['name'] == playlist['name']);
    if (playlistIndex != -1) {
      if (!playlists[playlistIndex]['songs'].any((s) => s['id'] == song['id'])) {
        playlists[playlistIndex]['songs'].add(song);
        await savePlaylists(playlists);
      }
    }
  }

  Future<void> removeSongFromPlaylist(Map<String, dynamic> playlist, Map<String, dynamic> song) async {
    final playlists = await loadPlaylists();
    final playlistIndex = playlists.indexWhere((p) => p['name'] == playlist['name']);
    if (playlistIndex != -1) {
      playlists[playlistIndex]['songs'].removeWhere((s) => s['id'] == song['id']);
      await savePlaylists(playlists);
    }
  }

  Future<void> updatePlaylistImage(String playlistName, String imagePath) async {
    final playlists = await loadPlaylists();
    final playlistIndex = playlists.indexWhere((p) => p['name'] == playlistName);
    if (playlistIndex != -1) {
      playlists[playlistIndex]['image'] = imagePath;
      await savePlaylists(playlists);
    }
  }
}