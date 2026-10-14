import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/request/create_character_request.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fixtures/race_traits_fixture.dart';

String? operationNameOf(Request request) => request
    .operation
    .document
    .definitions
    .whereType<OperationDefinitionNode>()
    .first
    .name
    ?.value;

const _request = CreateCharacterRequest(
  name: 'Aldo',
  sex: SexType.male,
  pronoun: PronounType.he,
  race: RaceType.human,
  classType: ClassType.fighter,
  age: 30,
);

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  KlimmeckGraphQl buildGraphQl() => KlimmeckGraphQl(
    resolveClient: () => GraphQLClient(
      link: Link.function((request, [forward]) {
        requests.add(request);
        return handler(request);
      }),
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  Stream<Response> data(Map<String, dynamic> data) =>
      Stream.value(Response(response: {'data': data}, data: data));

  Map<String, dynamic> userJson() => {
    'id': testUserId,
    'twitchId': testTwitchId,
    'twitchPoints': 10,
    'role': 'adventurer',
    'currentCharacter': {'id': testCharacterId},
  };

  setUp(() {
    requests = [];
    handler = (_) => data({});
  });

  group('createCharacter', () {
    test(
      'sends the CreateCharacter operation with the input variable',
      () async {
        handler = (_) => data({'createCharacter': userJson()});

        final user = await buildGraphQl().createCharacter(_request);

        expect(operationNameOf(requests.single), 'CreateCharacter');
        expect(requests.single.variables, {'input': _request.toJson()});
        expect(user.currentCharacter?.id, testCharacterId);
      },
    );

    test('throws the raw OperationException keeping the error code', () async {
      handler = (_) => Stream.value(
        Response(
          response: const {},
          errors: [
            GraphQLError(
              message: 'x',
              extensions: {'code': 'CHARACTER_NAME_TAKEN'},
            ),
          ],
        ),
      );

      await expectLater(
        buildGraphQl().createCharacter(_request),
        throwsA(
          isA<OperationException>().having(
            (e) => e.graphqlErrors.first.extensions?['code'],
            'code',
            'CHARACTER_NAME_TAKEN',
          ),
        ),
      );
    });

    test('throws FormatException when the user is missing', () async {
      handler = (_) => data({'createCharacter': null});

      await expectLater(
        buildGraphQl().createCharacter(_request),
        throwsFormatException,
      );
    });

    test('throws FormatException when the user is malformed', () async {
      handler = (_) => data({'createCharacter': userJson()..['id'] = null});

      await expectLater(
        buildGraphQl().createCharacter(_request),
        throwsFormatException,
      );
    });
  });

  group('getRaceTraits', () {
    test('returns the traits and skips unknown races', () async {
      handler = (_) => data({
        'raceTraits': [
          ...raceTraitsJson,
          {'race': 'centaur', 'minAge': 1, 'maxAge': 2},
        ],
      });

      final traits = await buildGraphQl().getRaceTraits();

      expect(operationNameOf(requests.single), 'GetRaceTraits');
      expect(traits, hasLength(9));
    });

    test('throws FormatException when raceTraits is missing', () async {
      await expectLater(buildGraphQl().getRaceTraits(), throwsFormatException);
    });
  });

  group('getMe', () {
    test('sends GetMe and parses the user', () async {
      handler = (_) => data({'me': userJson()});

      final user = await buildGraphQl().getMe();

      expect(operationNameOf(requests.single), 'GetMe');
      expect(user.id, testUserId);
    });

    test('throws FormatException on an unknown role', () async {
      handler = (_) => data({'me': userJson()..['role'] = 'overlord'});

      await expectLater(buildGraphQl().getMe(), throwsFormatException);
    });
  });
}
