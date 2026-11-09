import 'package:flutter/foundation.dart';

/// Destinazione di una riga di log.
typedef AppLogSink = void Function(String message);

/// Unico punto di log dell'app (D-03c): muto in release, `debugPrint` altrove.
void appLog(String message) =>
    appLogWith(message, isRelease: kReleaseMode, sink: debugPrint);

/// Variante pura di [appLog]: modalità di build e destinazione iniettate.
@visibleForTesting
void appLogWith(
  String message, {
  required bool isRelease,
  required AppLogSink sink,
}) {
  if (isRelease) return;
  sink(message);
}
