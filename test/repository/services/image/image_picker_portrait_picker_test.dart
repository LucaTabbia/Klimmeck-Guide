import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:klimmeck_guide/repository/services/image/image_picker_portrait_picker.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockImagePicker picker;
  late ImagePickerPortraitPicker portraitPicker;

  setUpAll(() => registerFallbackValue(ImageSource.gallery));

  setUp(() {
    picker = MockImagePicker();
    portraitPicker = ImagePickerPortraitPicker(picker);
  });

  void stubPick(Future<XFile?> Function() answer) {
    when(
      () => picker.pickImage(
        source: any(named: 'source'),
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
        requestFullMetadata: any(named: 'requestFullMetadata'),
      ),
    ).thenAnswer((_) => answer());
  }

  void verifyPickedFrom(ImageSource source) {
    verify(
      () => picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      ),
    ).called(1);
  }

  test('gallery pick downscales and returns the path', () async {
    stubPick(() async => XFile('/tmp/a.jpg'));

    expect(await portraitPicker.pick(PortraitSource.gallery), '/tmp/a.jpg');
    verifyPickedFrom(ImageSource.gallery);
  });

  test('camera pick uses the camera source with the same limits', () async {
    stubPick(() async => XFile('/tmp/b.jpg'));

    expect(await portraitPicker.pick(PortraitSource.camera), '/tmp/b.jpg');
    verifyPickedFrom(ImageSource.camera);
  });

  test('cancel returns null', () async {
    stubPick(() async => null);

    expect(await portraitPicker.pick(PortraitSource.gallery), isNull);
  });

  Future<void> expectFailure(String code, PortraitPickFailure failure) async {
    stubPick(() async => throw PlatformException(code: code));

    await expectLater(
      portraitPicker.pick(PortraitSource.camera),
      throwsA(
        isA<PortraitPickException>().having(
          (e) => e.failure,
          'failure',
          failure,
        ),
      ),
    );
  }

  test('photo_access_denied maps to permissionDenied', () {
    return expectFailure(
      'photo_access_denied',
      PortraitPickFailure.permissionDenied,
    );
  });

  test('camera_access_denied maps to permissionDenied', () {
    return expectFailure(
      'camera_access_denied',
      PortraitPickFailure.permissionDenied,
    );
  });

  test('no_available_camera maps to cameraUnavailable', () {
    return expectFailure(
      'no_available_camera',
      PortraitPickFailure.cameraUnavailable,
    );
  });

  test('other platform codes map to unknown', () {
    return expectFailure('invalid_image', PortraitPickFailure.unknown);
  });
}
