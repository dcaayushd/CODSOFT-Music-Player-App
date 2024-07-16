import 'package:flutter/material.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 36),
          onPressed: () {},
        ),
        const SizedBox(width: 32),
        IconButton(
          icon: const Icon(Icons.play_arrow, size: 64),
          onPressed: () {},
        ),
        const SizedBox(width: 32),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 36),
          onPressed: () {},
        ),
      ],
    );
  }
}