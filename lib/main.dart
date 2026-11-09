import 'package:klimmeck_guide/bootstrap/app_bootstrap.dart';
import 'package:klimmeck_guide/bootstrap/session_auth_composition.dart';

/// Entry point di produzione (D-01): solo la sessione reale.
Future<void> main() => bootstrapApp(buildAuth: buildSessionAuthComposition);
