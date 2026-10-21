import 'package:flutter/foundation.dart';
import 'package:klimmeck_guide/repository/services/push/link_opener.dart';
import 'package:url_launcher/url_launcher.dart';

/// Adapter di [LinkOpener] su url_launcher: apre sempre in un'app esterna.
class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  /// Niente `canLaunchUrl` (richiederebbe `<queries>` su Android 11+): si prova e si
  /// gestisce il fallimento.
  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (error) {
      debugPrint('Link not opened (${error.runtimeType})');
      return false;
    }
  }
}
