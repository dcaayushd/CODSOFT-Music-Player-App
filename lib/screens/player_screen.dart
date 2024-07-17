import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:musicify/utils/utils.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({required this.player, super.key});
  final AssetsAudioPlayer player;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isPlaying = true;
  bool isFavorite = false;
  @override
  void initState() {
    widget.player.isPlaying.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = event;
        });
      }
    });

    widget.player.onReadyToPlay.listen((newDuration) {
      if (mounted) {
        setState(() {
          duration = newDuration?.duration ?? Duration.zero;
        });
      }
    });

    widget.player.currentPosition.listen((newPosition) {
      if (mounted) {
        setState(() {
          position = newPosition;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 30,
                color: Colors.white,
              )),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          FutureBuilder<PaletteGenerator>(
            future: getImageColors(widget.player),
            builder: (context, snapshot) {
              return Container(
                color: snapshot.data?.mutedColor?.color,
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(.7)
                  ])),
            ),
          ),
          Positioned(
            height: MediaQuery.of(context).size.height / 1.5,
            child: Column(
              children: [
                Text(
                  widget.player.getCurrentAudioTitle,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  widget.player.getCurrentAudioArtist,
                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 20,
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Text(
                        durationFormat(position),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const VerticalDivider(
                        color: Colors.white54,
                        thickness: 2,
                        width: 25,
                        indent: 2,
                        endIndent: 2,
                      ),
                      Text(
                        durationFormat(duration - position),
                        style: const TextStyle(color: kPrimaryColor),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Center(
              child: SleekCircularSlider(
            min: 0,
            max: duration.inSeconds.toDouble(),
            initialValue: position.inSeconds.toDouble(),
            onChange: (value) async {
              await widget.player.seek(Duration(seconds: value.toInt()));
            },
            innerWidget: (percentage) {
              return Padding(
                padding: const EdgeInsets.all(25.0),
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  backgroundImage: AssetImage(
                      widget.player.getCurrentAudioImage?.path ?? ''),
                ),
              );
            },
            appearance: CircularSliderAppearance(
                size: 330,
                angleRange: 300,
                startAngle: 300,
                customColors: CustomSliderColors(
                    progressBarColor: kPrimaryColor,
                    dotColor: kPrimaryColor,
                    trackColor: Colors.grey.withOpacity(.4)),
                customWidths: CustomSliderWidths(
                    trackWidth: 6, handlerSize: 10, progressBarWidth: 6)),
          )),
          Positioned(
            top: MediaQuery.of(context).size.height / 1.3,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                          onPressed: () async {
                            await widget.player.previous();
                          },
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            size: 50,
                            color: Colors.white,
                          )),
                      IconButton(
                        onPressed: () async {
                          await widget.player.playOrPause();
                        },
                        padding: EdgeInsets.zero,
                        icon: isPlaying
                            ? const Icon(
                                Icons.pause_circle,
                                size: 70,
                                color: Colors.white,
                              )
                            : const Icon(
                                Icons.play_circle,
                                size: 70,
                                color: Colors.white,
                              ),
                      ),
                      IconButton(
                          onPressed: () async {
                            await widget.player.next();
                          },
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            size: 50,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Implement shuffle functionality
                        widget.player.toggleShuffle();
                      },
                      icon: const Icon(
                        Icons.shuffle,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Implement like/add to favorites functionality
                        // You might want to use a state management solution to keep track of favorites
                        // For now, we'll just toggle the icon color
                        setState(() {
                          isFavorite = !isFavorite;
                        });
                      },
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Implement add to playlist functionality
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Add to Playlist"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      // Add to existing playlist logic
                                      Navigator.pop(context);
                                    },
                                    child: Text("Add to Existing Playlist"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Create new playlist logic
                                      Navigator.pop(context);
                                    },
                                    child: Text("Create New Playlist"),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.playlist_add,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}