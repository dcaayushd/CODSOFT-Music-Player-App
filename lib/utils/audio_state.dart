import 'dart:async';

class AudioState {
  static final AudioState _instance = AudioState._internal();
  factory AudioState() => _instance;
  AudioState._internal();

  final _audioStateController = StreamController<void>.broadcast();
  Stream<void> get audioStateStream => _audioStateController.stream;

  void notifyAudioStateChanged() {
    _audioStateController.add(null);
  }

  void dispose() {
    _audioStateController.close();
  }
}