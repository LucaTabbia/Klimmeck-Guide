import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/user.dart';

const String testAccessToken = 'dev-stub-token-test';
const String testUserId = 'user-test-id';
const String testTwitchId = 'twitch-test-id';
const String testCharacterId = 'character-test-id';

User buildTestUser({RoleType role = RoleType.adventurer}) => User(
  id: testUserId,
  twitchId: testTwitchId,
  twitchPoints: 0,
  currentCharacter: null,
  role: role,
);

User buildTestUserWithCharacter({String characterId = testCharacterId}) =>
    buildTestUser().copyWith(
      currentCharacter: Character.fromJson({'id': characterId}),
    );
