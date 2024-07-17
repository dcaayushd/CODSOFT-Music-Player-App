import 'dart:math' as math;

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:musicify/screens/home_screen.dart';
import 'package:musicify/screens/library_screen.dart';
import 'package:musicify/screens/player_screen.dart';
import 'package:musicify/screens/search_screen.dart';
import 'package:musicify/utils/utils.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final player = AssetsAudioPlayer();
  bool isPlaying = false;

  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    player.isPlaying.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = event;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(player: player),
          const SearchScreen(),
          const LibraryScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          player.getCurrentAudioImage == null
              ? const SizedBox.shrink()
              : FutureBuilder<PaletteGenerator>(
                  future: getImageColors(player),
                  builder: (context, snapshot) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      height: 75,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: const Alignment(0, 5),
                              colors: [
                                snapshot.data?.lightMutedColor?.color ??
                                    Colors.grey,
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
                                  ? const Icon(CupertinoIcons.pause)
                                  : const Icon(CupertinoIcons.play_arrow),
                            ),
                            IconButton(
                              onPressed: () async {
                                await player.next();
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
                ),
          FutureBuilder<PaletteGenerator>(
            future: getImageColors(player),
            builder: (context, snapshot) {
              final selectedColor =
                  snapshot.data?.lightMutedColor?.color ?? Colors.white;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, bottom: 0, top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(CupertinoIcons.square_grid_2x2, 'Home', 0,
                            selectedColor),
                        _buildNavItem(
                            CupertinoIcons.search, 'Search', 1, selectedColor),
                        _buildNavItem(CupertinoIcons.music_note_list, 'Library',
                            2, selectedColor),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, int index, Color selectedColor) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _currentIndex == index ? selectedColor : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              color: _currentIndex == index ? selectedColor : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
