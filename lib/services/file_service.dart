import 'package:file_picker/file_picker.dart';
import '../models/song.dart';
import 'package:path/path.dart' as path;

class FileService {
  Future<Song?> pickSong() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      String filePath = result.files.single.path!;
      String fileName = path.basename(filePath);
      String title = path.basenameWithoutExtension(fileName);
      
      return Song(
        title: title,
        artist: 'Unknown Artist', 
        filePath: filePath,
      );
    }
    return null;
  }
}