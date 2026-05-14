import 'package:image_picker/image_picker.dart';

/// Otwiera natywny aparat — logika wyboru źródła obrazu poza UI.
class CameraCaptureService {
  CameraCaptureService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> capturePhoto({int imageQuality = 85}) {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
    );
  }
}
