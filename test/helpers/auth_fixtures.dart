import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/user.dart';

const String testAccessToken = 'dev-stub-token-test';
const String testUserId = 'user-test-id';
const String testTwitchId = 'twitch-test-id';

User buildTestUser({RoleType role = RoleType.adventurer}) => User(
      id: testUserId,
      twitchId: testTwitchId,
      twitchPoints: 0,
      currentCharacter: null,
      role: role,
    );
