import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Zapisuje plik z aparatu w katalogu aplikacji (trwała ścieżka dla cache / późniejszego uploadu).
class ImageStorageService {
  static const _subDir = 'scan_media';

  Future<String> persistCameraImage(XFile file) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_subDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final name = '${const Uuid().v4()}.jpg';
    final target = File('${dir.path}/$name');
    await File(file.path).copy(target.path);
    return target.path;
  }

  Future<void> deleteIfExists(String path) async {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }
}
