import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:musicify/widgets/song_list_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/audio_service.dart';

class SearchScreen extends StatefulWidget {
  final AssetsAudioPlayer player;

  const SearchScreen({
    super.key,
    required this.player,
  });

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final AudioService _audioService = AudioService();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  List<AlbumModel> _albums = [];
  List<SongModel> _filteredSongs = [];
  List<AlbumModel> _filteredAlbums = [];
  List<String> _recentSearches = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchSongsAndAlbums();
    _loadRecentSearches();
  }

  void _fetchSongsAndAlbums() async {
    _songs = await _audioQuery.querySongs(
      ignoreCase: true,
      orderType: OrderType.ASC_OR_SMALLER,
      sortType: null,
      uriType: UriType.EXTERNAL,
    );
    _albums = await _audioQuery.queryAlbums();
  }

  void _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  void _saveRecentSearch(String query) async {
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', _recentSearches);
    }
  }

  void _clearRecentSearches() async {
    setState(() {
      _recentSearches.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
  }

  void _filterSongsAndAlbums(String query) {
    setState(() {
      _filteredSongs = _songs
          .where((song) =>
              song.title.toLowerCase().contains(query.toLowerCase()) ||
              (song.artist?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList();
      _filteredAlbums = _albums
          .where((album) =>
              album.album.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _isSearching = query.isNotEmpty;
    });
  }

  void _performSearch() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      _filterSongsAndAlbums(query);
      _saveRecentSearch(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: TextField(
          controller: _searchController,
          onChanged: _filterSongsAndAlbums,
          decoration: InputDecoration(
            hintText: 'Search songs, artists or albums',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[700],
            prefixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _performSearch,
            ),
            suffixIcon: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterSongsAndAlbums('');
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _isSearching ? _buildSearchResults() : _buildInitialContent(),
    );
  }

  Widget _buildInitialContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Searches',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          Wrap(
            children: _recentSearches
                .map((search) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: InkWell(
                        onTap: () {
                          _searchController.text = search;
                          _performSearch();
                        },
                        child: Chip(
                          label: Text(search),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Songs'),
              Tab(text: 'Albums'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView.builder(
                  itemCount: _filteredSongs.length,
                  itemBuilder: (context, index) {
                    return SongListItem(
                      song: _filteredSongs[index],
                      player: widget.player,
                      onTap: () async {
                        await _audioService.player.stop();

                        int selectedIndex = _songs.indexWhere(
                            (song) => song.id == _filteredSongs[index].id);

                        if (selectedIndex != -1) {
                          List<Audio> playlist = _songs
                              .sublist(selectedIndex)
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

                          _saveRecentSearch(_searchController.text);

                          if (Navigator.canPop(context)) {
                            Navigator.pop(context, _filteredSongs[index]);
                          }
                        }
                      },
                    );
                  },
                ),
                ListView.builder(
                  itemCount: _filteredAlbums.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_filteredAlbums[index].album),
                      subtitle: Text(
                          _filteredAlbums[index].artist ?? 'Unknown Artist'),
                      onTap: () {
                        // Handle album selection
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
