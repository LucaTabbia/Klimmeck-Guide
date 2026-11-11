import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/env_config.dart';

/// Inizializza dotenv con valori di test (letti da `DevAuthTokenService`) e
/// installa gli stessi valori come runtime override di [EnvConfig]; override e
/// dotenv sono svuotati a fine test. Chiamare in `setUp()` o nel test.
/// Usa [DotEnv.loadFromString] (API flutter_dotenv 6.x) per inizializzazione
/// sincrona da stringa in-memory — i test non toccano mai il file .env su disco.
/// Ogni chiave è override-abile via parametri nominati.
Future<void> loadTestEnv({
  String devAuthEnabled = 'true',
  String accessToken = 'dev-stub-token-test',
  String userId = 'user-test-id',
  String twitchId = 'twitch-test-id',
  String role = 'adventurer',
  String startSignedOut = 'false',
}) async {
  dotenv.loadFromString(
    envString:
        '''
DEV_AUTH_ENABLED=$devAuthEnabled
DEV_AUTH_ACCESS_TOKEN=$accessToken
DEV_AUTH_USER_ID=$userId
DEV_AUTH_TWITCH_ID=$twitchId
DEV_AUTH_ROLE=$role
DEV_AUTH_START_SIGNED_OUT=$startSignedOut
''',
  );
  EnvConfig.installRuntimeOverrides(dotenv.env);
  addTearDown(() {
    EnvConfig.resetRuntimeOverrides();
    dotenv.clean();
  });
}
