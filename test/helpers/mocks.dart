import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/backend_auth_api.dart';
import 'package:klimmeck_guide/repository/services/auth/browser_authenticator.dart';
import 'package:klimmeck_guide/repository/services/auth/unauthorized_recovery.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/rest/rest.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock condivisi della suite. Ogni plan della Phase 11 aggiunge qui i propri mock:
/// mai ridefinire un mock in un singolo file di test.
class MockAuthTokenService extends Mock implements AuthTokenService {}

class MockUnauthorizedRecovery extends Mock implements UnauthorizedRecovery {}

class MockBrowserAuthenticator extends Mock implements BrowserAuthenticator {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockBackendAuthApi extends Mock implements BackendAuthApi {}

class MockBackendMeSource extends Mock implements BackendMeSource {}

/// Forma dell'hook `onSessionTeardown`, per verificarne l'ordine con `verifyInOrder`.
abstract interface class SessionTeardownHook {
  Future<void> call();
}

class MockSessionTeardownHook extends Mock implements SessionTeardownHook {}

class MockKlimmeckRest extends Mock implements KlimmeckRest {}

class MockKlimmeckGraphQl extends Mock implements KlimmeckGraphQl {}

class MockSplashCubit extends MockCubit<SplashState> implements SplashCubit {}
