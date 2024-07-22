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