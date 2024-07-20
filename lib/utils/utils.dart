// import 'dart:io';

// import 'package:assets_audio_player/assets_audio_player.dart';
// import 'package:flutter/material.dart';
// import 'package:palette_generator/palette_generator.dart';

// const kPrimaryColor = Color(0xFFebbe8b);

// // playlist songs
// List<Audio> songs = [
//   Audio('assets/nf_Let_You_Down.mp3',
//       metas: Metas(
//           title: 'Let You Down',
//           artist: 'NF',
//           image: const MetasImage.asset(
//               'assets/1b7f41e39f3d6ac58798a500eb4a0e2901f4502dv2_hq.jpeg'))),
//   Audio('assets/lil_nas_x_industry_baby.mp3',
//       metas: Metas(
//           title: 'Industry Baby',
//           artist: 'Lil Nas X',
//           image: const MetasImage.asset('assets/81Uj3NtUuhL._SS500_.jpg'))),
//   Audio('assets/Beautiful.mp3',
//       metas: Metas(
//           title: 'Beautiful',
//           artist: 'Eminem',
//           image: const MetasImage.asset('assets/916WuJt833L._SS500_.jpg'))),
// ];

// String durationFormat(Duration duration) {
//   String twoDigits(int n) => n.toString().padLeft(2, '0');
//   String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
//   String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//   return '$twoDigitMinutes:$twoDigitSeconds';
//   // for example => 03:09
// }

// // get song cover image colors
// // Future<PaletteGenerator> getImageColors(AssetsAudioPlayer player) async {
// //   var paletteGenerator = await PaletteGenerator.fromImageProvider(
// //     AssetImage(player.getCurrentAudioImage?.path ?? ''),
// //   );
// //   return paletteGenerator;
// // }


// // Future<PaletteGenerator> getImageColors(AssetsAudioPlayer player) async {
// //   final metas = await player.current.first;
// //   final image = metas?.audio.audio.metas.image;

// //   if (image == null) {
// //     return PaletteGenerator.fromColors([PaletteColor(Colors.grey, 1)]);
// //   }

// //   if (image.path.startsWith('assets')) {
// //     return PaletteGenerator.fromImageProvider(AssetImage(image.path));
// //   } else {
// //     return PaletteGenerator.fromImageProvider(FileImage(image.path as File));
// //   }
// // }

// Future<PaletteGenerator> getImageColors(AssetsAudioPlayer player) async {
//   final metas = await player.current.first;
//   final imagePath = metas?.audio.audio.metas.image?.path;
//   if (imagePath == null) {
//     return PaletteGenerator.fromColors([PaletteColor(Colors.grey, 1)]);
//   }
  
//   try {
//     File imageFile = File(imagePath);
//     if (await imageFile.exists()) {
//       return PaletteGenerator.fromImageProvider(FileImage(imageFile));
//     } else {
//       // If file doesn't exist, use a default color
//       return PaletteGenerator.fromColors([PaletteColor(Colors.grey, 1)]);
//     }
//   } catch (e) {
//     debugPrint("Error loading image: $e");
//     return PaletteGenerator.fromColors([PaletteColor(Colors.grey, 1)]);
//   }
// }


// utils.dart


import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

const kPrimaryColor = Color(0xFFebbe8b);

// playlist songs
List<Audio> songs = [
  Audio('assets/nf_Let_You_Down.mp3',
      metas: Metas(
          title: 'Let You Down',
          artist: 'NF',
          image: const MetasImage.asset('assets/1b7f41e39f3d6ac58798a500eb4a0e2901f4502dv2_hq.jpeg'))),
  Audio('assets/lil_nas_x_industry_baby.mp3',
      metas: Metas(
          title: 'Industry Baby',
          artist: 'Lil Nas X',
          image: const MetasImage.asset('assets/81Uj3NtUuhL._SS500_.jpg'))),
  Audio('assets/Beautiful.mp3',
      metas: Metas(
          title: 'Beautiful',
          artist: 'Eminem',
          image: const MetasImage.asset('assets/916WuJt833L._SS500_.jpg'))),
];

String durationFormat(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return '$twoDigitMinutes:$twoDigitSeconds';
}


Future<PaletteGenerator> getImageColors(AssetsAudioPlayer player) async {
  final metas = await player.current.first;
  final songId = int.tryParse(metas?.audio.audio.metas.id ?? '0') ?? 0;

  try {
    final artworkFile = await OnAudioQuery().queryArtwork(
      songId,
      ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size: 200,
    );

    if (artworkFile != null) {
      return PaletteGenerator.fromImageProvider(MemoryImage(artworkFile));
    } else {
      // If no artwork is found, use a default color
      return PaletteGenerator.fromColors([PaletteColor(Colors.grey, 1)]);
    }
  } catch (e) {
    debugPrint("Error loading image colors: $e");
    return PaletteGenerator.fromColors([PaletteColor(Colors.grey, 1)]);
  }
}



// Future<PaletteGenerator> getImageColors(AssetsAudioPlayer player) async {
//   final metas = await player.current.first;
//   final imagePath = metas?.audio.audio.metas.image?.path;
//   if (imagePath == null) {
//     return PaletteGenerator.fromColors([PaletteColor(Colors.grey, 1)]);
//   }
  
//   try {
//     if (imagePath.startsWith('assets/')) {
//       // Asset image
//       return PaletteGenerator.fromImageProvider(AssetImage(imagePath));
//     } else {
//       // File image
//       File imageFile = File(imagePath);
//       if (await imageFile.exists()) {
//         return PaletteGenerator.fromImageProvider(FileImage(imageFile));
//       } else {
//         // If file doesn't exist, use a default color
//         return PaletteGenerator.fromColors([PaletteColor(Colors.grey, 1)]);
//       }
//     }
//   } catch (e) {
//     debugPrint("Error loading image: $e");
//     return PaletteGenerator.fromColors([PaletteColor(Colors.grey, 1)]);
//   }
// }