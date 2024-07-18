import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:musicify/widgets/song_list_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  final AssetsAudioPlayer player;
  final Function(SongModel) onSongSelected;

  const SearchScreen({
    super.key,
    required this.player,
    required this.onSongSelected,
  });

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  List<AlbumModel> _albums = [];
  List<SongModel> _filteredSongs = [];
  List<AlbumModel> _filteredAlbums = [];
  List<String> _recentSearches = [];
  List<SongModel> _suggestions = [];
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchSongsAndAlbums();
    _loadRecentSearches();
    _loadSuggestions();
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

  void _loadSuggestions() {
    _suggestions = _songs.take(5).toList();
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
    if (query.isNotEmpty) {
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
            fillColor: Colors.grey[200],
            prefixIcon: const Icon(Icons.search),
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
          style: const TextStyle(color: Colors.black),
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
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Wrap(
            children: _recentSearches
                .map((search) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Chip(
                        label: Text(search),
                        onDeleted: () {
                          setState(() {
                            _recentSearches.remove(search);
                          });
                        },
                      ),
                    ))
                .toList(),
          ),
        ],
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Suggestions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              return SongListItem(
                song: _suggestions[index],
                player: widget.player,
                // onTap: () {
                //   widget.onSongSelected(_suggestions[index]);
                // },
                onTap: () async {
                  await widget.player.open(
                    Audio.file(
                      _filteredSongs[index].data,
                      metas: Metas(
                        id: _filteredSongs[index].id.toString(),
                        title: _filteredSongs[index].title,
                        artist: _filteredSongs[index].artist,
                        album: _filteredSongs[index].album,
                      ),
                    ),
                    showNotification: true,
                  );
                  widget.onSongSelected(_filteredSongs[index]);
                },
              );
            },
          ),
        ),
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
                      // onTap: () {
                      //   widget.onSongSelected(_filteredSongs[index]);
                      // },
                      onTap: () async {
                        await widget.player.open(
                          Audio.file(
                            _filteredSongs[index].data,
                            metas: Metas(
                              id: _filteredSongs[index].id.toString(),
                              title: _filteredSongs[index].title,
                              artist: _filteredSongs[index].artist,
                              album: _filteredSongs[index].album,
                            ),
                          ),
                          showNotification: true,
                        );
                        widget.onSongSelected(_filteredSongs[index]);
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
