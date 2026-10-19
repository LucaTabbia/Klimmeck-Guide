import 'package:klimmeck_guide/repository/services/push/link_opener.dart';

/// [LinkOpener] che registra i link aperti e restituisce [result].
class RecordingLinkOpener implements LinkOpener {
  final List<Uri> opened = [];
  bool result = true;

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return result;
  }
}
