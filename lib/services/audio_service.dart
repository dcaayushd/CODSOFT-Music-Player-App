import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:musicify/models/track.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPickerOpen = false;

  Future<List<Track>> loadTracks() async {
    if (_isPickerOpen) {
      return [];
    }

    try {
      _isPickerOpen = true;
      await _requestPermissions();
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        return result.files.map((file) {
          return Track(
            title: file.name,
            artist: 'Unknown',
            filePath: file.path!,
          );
        }).toList();
      }
    } catch (e) {
      print('Error loading tracks: $e');
    } finally {
      _isPickerOpen = false;
    }

    return [];
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.mediaLibrary.request();
  }

  void play(Track track) async {
    await _audioPlayer.play(DeviceFileSource(track.filePath));
  }

  void pause() {
    _audioPlayer.pause();
  }

  void stop() {
    _audioPlayer.stop();
  }
}