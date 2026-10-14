import 'package:gql_exec/gql_exec.dart';

import '../auth_fixtures.dart';

Map<String, dynamic> userJson({
  String id = testUserId,
  int twitchPoints = 0,
  String role = 'adventurer',
  String? characterId,
}) => {
  'id': id,
  'twitchId': testTwitchId,
  'twitchPoints': twitchPoints,
  'role': role,
  'currentCharacter': characterId == null ? null : {'id': characterId},
};

Map<String, dynamic> characterJson({
  String id = testCharacterId,
  int currentLifePoints = 10,
  int maxLifePoints = 10,
  int gold = 0,
}) => {
  'id': id,
  'status': {
    'currentLifePoints': currentLifePoints,
    'maxLifePoints': maxLifePoints,
    'coins': {'gold': gold, 'silver': 0, 'copper': 0},
  },
};

Response dataResponse(Map<String, dynamic> data) =>
    Response(response: {'data': data}, data: data);

Response errorCodeResponse(String code) => Response(
  response: const {},
  data: null,
  errors: [
    GraphQLError(message: code, extensions: {'code': code}),
  ],
);

Response malformedUserResponse() => dataResponse({
  'userUpdated': {'id': 42},
});
