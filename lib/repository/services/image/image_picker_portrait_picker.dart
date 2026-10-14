import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';

/// [PortraitPicker] basato su `image_picker`: ridimensiona nativamente.
///
/// Rischio accettato: su Android l'activity può essere terminata durante
/// l'intent della fotocamera; `retrieveLostData` non è usato perché l'intero
/// form provvisorio andrebbe comunque perso.
class ImagePickerPortraitPicker implements PortraitPicker {
  ImagePickerPortraitPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  static const double maxSide = 1024;
  static const int quality = 85;

  final ImagePicker _picker;

  @override
  Future<String?> pick(PortraitSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == PortraitSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: quality,
        requestFullMetadata: false,
      );
      return file?.path;
    } on PlatformException catch (error) {
      throw PortraitPickException(_failureFor(error.code));
    }
  }

  static PortraitPickFailure _failureFor(String code) => switch (code) {
    'photo_access_denied' ||
    'camera_access_denied' => PortraitPickFailure.permissionDenied,
    'no_available_camera' => PortraitPickFailure.cameraUnavailable,
    _ => PortraitPickFailure.unknown,
  };
}
