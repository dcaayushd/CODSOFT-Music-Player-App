import 'package:flutter/material.dart';
import 'package:musicify/screens/music_player_screen.dart';

void main() {
  runApp(const MusicifyApp());
}

class MusicifyApp extends StatelessWidget {
  const MusicifyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Musicify',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MusicPlayerScreen(),
    );
  }
}
