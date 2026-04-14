import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Inizializza dotenv con valori di test. Chiamare in `setUp()`.
/// Usa [DotEnv.loadFromString] (API flutter_dotenv 6.x) per inizializzazione
/// sincrona da stringa in-memory — i test non toccano mai il file .env su disco.
/// Ogni chiave è override-abile via parametri nominati.
Future<void> loadTestEnv({
  String devAuthEnabled = 'true',
  String accessToken = 'dev-stub-token-test',
  String userId = 'user-test-id',
  String twitchId = 'twitch-test-id',
  String role = 'adventurer',
}) async {
  dotenv.loadFromString(envString: '''
DEV_AUTH_ENABLED=$devAuthEnabled
DEV_AUTH_ACCESS_TOKEN=$accessToken
DEV_AUTH_USER_ID=$userId
DEV_AUTH_TWITCH_ID=$twitchId
DEV_AUTH_ROLE=$role
''');
}
