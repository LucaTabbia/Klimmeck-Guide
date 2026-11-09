import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';

const String _serverMessage = 'internal detail from the server';

void main() {
  test(
    'a failed lore read keeps no exception text in the error state',
    () async {
      final graphQl = MockKlimmeckGraphQl();
      when(() => graphQl.getLoreById('lore-1')).thenAnswer(
        (_) async => throw OperationException(
          graphqlErrors: const [GraphQLError(message: _serverMessage)],
        ),
      );
      final cubit = WorldMapCubit(graphQl);

      await cubit.loadLoreData('lore-1');

      expect(cubit.state, isA<WorldMapError>());
      expect(cubit.state.props.join(), isNot(contains(_serverMessage)));
      await cubit.close();
    },
  );
}
