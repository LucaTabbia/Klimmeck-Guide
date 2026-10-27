import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:klimmeck_guide/repository/character_creation_repository.dart';
import 'package:klimmeck_guide/repository/character_deletion_repository.dart';
import 'package:klimmeck_guide/repository/push_device_repository.dart';
import 'package:klimmeck_guide/repository/quest_abandon_repository.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_repository.dart';
import 'package:klimmeck_guide/repository/quest_board_repository.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/backend_auth_api.dart';
import 'package:klimmeck_guide/repository/services/auth/browser_authenticator.dart';
import 'package:klimmeck_guide/repository/services/auth/session_terminator.dart';
import 'package:klimmeck_guide/repository/services/auth/unauthorized_recovery.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';
import 'package:klimmeck_guide/repository/services/push/push_session_cleanup.dart';
import 'package:klimmeck_guide/repository/services/rest/rest.dart';
import 'package:klimmeck_guide/repository/spells_repository.dart';
import 'package:klimmeck_guide/repository/travel_repository.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_creation_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock condivisi della suite. Ogni plan della Phase 11 aggiunge qui i propri mock:
/// mai ridefinire un mock in un singolo file di test.
class MockAuthTokenService extends Mock implements AuthTokenService {}

class MockUnauthorizedRecovery extends Mock implements UnauthorizedRecovery {}

class MockSessionTerminator extends Mock implements SessionTerminator {}

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

class MockImagePicker extends Mock implements ImagePicker {}

class MockPortraitPicker extends Mock implements PortraitPicker {}

class MockKlimmeckGraphQl extends Mock implements KlimmeckGraphQl {}

class MockCharacterCreationRepository extends Mock
    implements CharacterCreationRepository {}

class MockCharacterDeletionRepository extends Mock
    implements CharacterDeletionRepository {}

class MockQuestBoardRepository extends Mock implements QuestBoardRepository {}

class MockQuestAcceptanceRepository extends Mock
    implements QuestAcceptanceRepository {}

class MockQuestAbandonRepository extends Mock
    implements QuestAbandonRepository {}

class MockTravelRepository extends Mock implements TravelRepository {}

class MockSpellsRepository extends Mock implements SpellsRepository {}

class MockPushDeviceRepository extends Mock implements PushDeviceRepository {}

class MockPushSessionCleanup extends Mock implements PushSessionCleanup {}

class MockSplashCubit extends MockCubit<SplashState> implements SplashCubit {}

class MockCharacterCreationCubit extends MockCubit<CharacterCreationState>
    implements CharacterCreationCubit {}

class MockInAppNotificationsCubit extends MockCubit<InAppNotificationsState>
    implements InAppNotificationsCubit {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockCharacterCubit extends MockCubit<CharacterState>
    implements CharacterCubit {}

class MockQuestCubit extends MockCubit<QuestState> implements QuestCubit {}

class MockMainScreenCubit extends MockCubit<MainScreenState>
    implements MainScreenCubit {}

class MockNotificationPreferencesCubit
    extends MockCubit<NotificationPreferencesState>
    implements NotificationPreferencesCubit {}

class MockNotificationPermissionCubit
    extends MockCubit<NotificationPermissionState>
    implements NotificationPermissionCubit {}

class MockCharacterDeletionCubit extends MockCubit<CharacterDeletionState>
    implements CharacterDeletionCubit {}

class MockQuestAcceptanceCubit extends MockCubit<QuestAcceptanceState>
    implements QuestAcceptanceCubit {}

class MockQuestAbandonCubit extends MockCubit<QuestAbandonState>
    implements QuestAbandonCubit {}

class MockTravelCubit extends MockCubit<TravelState> implements TravelCubit {}

class MockSpellsCubit extends MockCubit<SpellsState> implements SpellsCubit {}

class MockTravelProgressCubit extends MockCubit<TravelProgressState>
    implements TravelProgressCubit {}

class MockWorldMapCubit extends MockCubit<WorldMapState>
    implements WorldMapCubit {}
