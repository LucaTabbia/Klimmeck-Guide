import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/auth/session_home.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_fixtures.dart';
import '../../helpers/fakes/recording_sync_health.dart';
import '../../helpers/mocks.dart';

void main() {
  late int creationBuilds;
  late int shellBuilds;

  setUp(() {
    creationBuilds = 0;
    shellBuilds = 0;
  });

  Widget buildHome(user) => MaterialApp(
    home: SessionHome(
      user: user,
      creationBuilder: (_) {
        creationBuilds++;
        return const Text('creation');
      },
      shellBuilder: (_, characterId) {
        shellBuilds++;
        return Text('shell $characterId');
      },
    ),
  );

  testWidgets('shows the creation screen when the user has no character', (
    tester,
  ) async {
    await tester.pumpWidget(buildHome(buildTestUser()));

    expect(find.text('creation'), findsOneWidget);
    expect(shellBuilds, 0);
  });

  testWidgets('shows the shell with the character id when one exists', (
    tester,
  ) async {
    await tester.pumpWidget(buildHome(buildTestUserWithCharacter()));

    expect(find.text('shell $testCharacterId'), findsOneWidget);
    expect(creationBuilds, 0);
  });

  testWidgets('swaps creation for the shell once the character exists', (
    tester,
  ) async {
    await tester.pumpWidget(buildHome(buildTestUser()));
    await tester.pumpWidget(buildHome(buildTestUserWithCharacter()));

    expect(find.text('creation'), findsNothing);
    expect(find.text('shell $testCharacterId'), findsOneWidget);
  });

  _characterKeyTests();
}

class _ShellSpy extends StatefulWidget {
  const _ShellSpy({required this.characterId, required this.log});

  final String characterId;
  final List<String> log;

  @override
  State<_ShellSpy> createState() => _ShellSpyState();
}

class _ShellSpyState extends State<_ShellSpy> {
  @override
  void initState() {
    super.initState();
    widget.log.add('init ${widget.characterId}');
  }

  @override
  void dispose() {
    widget.log.add('dispose ${widget.characterId}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('spy ${widget.characterId}');
}

void _characterKeyTests() {
  testWidgets('recreates the shell state when the character id changes', (
    tester,
  ) async {
    final log = <String>[];
    Widget home(String id) => MaterialApp(
      home: SessionHome(
        user: buildTestUserWithCharacter(characterId: id),
        creationBuilder: (_) => const Text('creation'),
        shellBuilder: (_, characterId) =>
            _ShellSpy(characterId: characterId, log: log),
      ),
    );

    await tester.pumpWidget(home('c1'));
    await tester.pumpWidget(home('c2'));

    expect(log, ['init c1', 'dispose c1', 'init c2']);
  });

  testWidgets('keeps the shell state when the same character is re-emitted', (
    tester,
  ) async {
    final log = <String>[];
    Widget home(int points) => MaterialApp(
      home: SessionHome(
        user: buildTestUserWithCharacter(
          characterId: 'c1',
        ).copyWith(twitchPoints: points),
        creationBuilder: (_) => const Text('creation'),
        shellBuilder: (_, characterId) =>
            _ShellSpy(characterId: characterId, log: log),
      ),
    );

    await tester.pumpWidget(home(1));
    await tester.pumpWidget(home(2));

    expect(log, ['init c1']);
  });

  group('character streams', () {
    late MockKlimmeckGraphQl api;
    late Map<String, StreamController<Character>> controllers;
    late UserRefreshRequestBus refreshBus;
    late AppLifecycleEventBus lifecycleBus;

    setUp(() {
      api = MockKlimmeckGraphQl();
      controllers = {};
      refreshBus = UserRefreshRequestBus();
      lifecycleBus = AppLifecycleEventBus();
      when(() => api.getCharacter(any())).thenAnswer(
        (invocation) async =>
            Character.fromJson({'id': invocation.positionalArguments.first}),
      );
      when(() => api.subscribeToCharacter(any())).thenAnswer((invocation) {
        final id = invocation.positionalArguments.first as String;
        return (controllers[id] = StreamController<Character>()).stream;
      });
    });

    tearDown(() async {
      await refreshBus.close();
      await lifecycleBus.close();
    });

    Widget home(User user) => MaterialApp(
      home: SessionHome(
        user: user,
        creationBuilder: (_) => const Text('creation'),
        shellBuilder: (_, characterId) => BlocProvider<CharacterCubit>(
          create: (_) => CharacterCubit(
            api,
            health: RecordingSyncHealth(),
            lifecycle: lifecycleBus,
            userRefresh: refreshBus,
          )..loadCharacter(characterId),
          child: Text('shell $characterId'),
        ),
      ),
    );

    testWidgets('only the new character stream is listened to after a switch', (
      tester,
    ) async {
      await tester.pumpWidget(
        home(buildTestUserWithCharacter(characterId: 'c1')),
      );
      await tester.pump();
      expect(controllers['c1']!.hasListener, isTrue);

      await tester.pumpWidget(
        home(buildTestUserWithCharacter(characterId: 'c2')),
      );
      await tester.pump();

      expect(controllers['c1']!.hasListener, isFalse);
      expect(controllers['c2']!.hasListener, isTrue);
    });

    testWidgets('drops the character stream when the character is deleted', (
      tester,
    ) async {
      await tester.pumpWidget(
        home(buildTestUserWithCharacter(characterId: 'c1')),
      );
      await tester.pump();

      await tester.pumpWidget(home(buildTestUser()));
      await tester.pump();

      expect(find.text('creation'), findsOneWidget);
      expect(controllers['c1']!.hasListener, isFalse);
    });
  });
}
