import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/backend_auth_api.dart';
import 'package:klimmeck_guide/repository/services/auth/browser_authenticator.dart';
import 'package:mocktail/mocktail.dart';

/// Mock condivisi della suite. Ogni plan della Phase 11 aggiunge qui i propri mock:
/// mai ridefinire un mock in un singolo file di test.
class MockAuthTokenService extends Mock implements AuthTokenService {}

class MockBrowserAuthenticator extends Mock implements BrowserAuthenticator {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockBackendAuthApi extends Mock implements BackendAuthApi {}

class MockBackendMeSource extends Mock implements BackendMeSource {}
