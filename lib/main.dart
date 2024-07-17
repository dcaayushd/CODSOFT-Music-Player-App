import 'package:flutter/material.dart';
import 'package:musicify/screens/playlist_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musicify',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      debugShowCheckedModeBanner: false,
      home: const PlaylistScreen(),
    );
  }
}
