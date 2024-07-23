import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/search_screen.dart';
import '../utils/utils.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final player = AssetsAudioPlayer();
  Color selectedNavColor = Colors.white;
  @override
  void initState() {
    super.initState();
    _updateNavColor();
  }

  void _updateNavColor() async {
    final colors = await getImageColors(player);
    setState(() {
      selectedNavColor = colors.lightMutedColor?.color ?? Colors.white;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          SearchScreen(player: player),
          LibraryScreen(player: player),
        ],
      ),
      bottomNavigationBar: Container(
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
                  left: 8.0, right: 8.0, bottom: 8, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(CupertinoIcons.square_grid_2x2, 'Home', 0,
                      selectedNavColor),
                  _buildNavItem(
                      CupertinoIcons.search, 'Search', 1, selectedNavColor),
                  _buildNavItem(
                      Icons.library_music, 'Library', 2, selectedNavColor),
                ],
              ),
            ),
          )
          // ,
          // );
          // },
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

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
