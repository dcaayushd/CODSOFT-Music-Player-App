import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesService {
  static const String _key = 'favorites';

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_key);
    if (favoritesJson == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(favoritesJson));
  }

  Future<void> addFavorite(Map<String, dynamic> song) async {
    final favorites = await getFavorites();
    if (!favorites.any((favorite) => favorite['id'] == song['id'])) {
      favorites.add(song);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(favorites));
    }
  }

  Future<void> removeFavorite(String id) async {
    final favorites = await getFavorites();
    favorites.removeWhere((favorite) => favorite['id'] == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(favorites));
  }
}