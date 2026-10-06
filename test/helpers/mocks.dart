import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/browser_authenticator.dart';
import 'package:mocktail/mocktail.dart';

/// Mock condivisi della suite. Ogni plan della Phase 11 aggiunge qui i propri mock:
/// mai ridefinire un mock in un singolo file di test.
class MockAuthTokenService extends Mock implements AuthTokenService {}

class MockBrowserAuthenticator extends Mock implements BrowserAuthenticator {}
