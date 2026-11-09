import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:klimmeck_guide/bootstrap/app_bootstrap.dart';
import 'package:klimmeck_guide/bootstrap/dev_auth_composition.dart';
import 'package:klimmeck_guide/config/env_config.dart';

/// Entry point di sviluppo (D-01, D-16): `flutter run --flavor dev -t
/// lib/main_dev.dart`. Carica `.env` e, con `DEV_AUTH_ENABLED=true`, il bypass
/// dev della Phase 11.
Future<void> main() async {
  assert(appFlavor == 'dev', 'Run with --flavor dev');
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  EnvConfig.installRuntimeOverrides(dotenv.env);
  await bootstrapApp(buildAuth: buildDevAuthComposition);
}
