import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/signIn/consentCubit/legal_consent_cubit.dart';

import '../../../helpers/fakes/in_memory_legal_consent_store.dart';

void main() {
  const version = 'v-test';
  const ticked = LegalConsentState(isAccepted: true);
  const unticked = LegalConsentState();

  late InMemoryLegalConsentStore store;

  setUp(() => store = InMemoryLegalConsentStore());

  LegalConsentCubit build() => LegalConsentCubit(store, version: version);

  test('starts unticked (D-07)', () {
    final cubit = build();
    addTearDown(cubit.close);

    expect(cubit.state, unticked);
  });

  blocTest<LegalConsentCubit, LegalConsentState>(
    'restore ticks when the stored version is the current one (D-10)',
    setUp: () => store.acceptedVersion = version,
    build: build,
    act: (cubit) => cubit.restore(),
    expect: () => [ticked],
  );

  blocTest<LegalConsentCubit, LegalConsentState>(
    'restore stays unticked for another stored version (D-10, D-12)',
    setUp: () => store.acceptedVersion = 'v-old',
    build: build,
    act: (cubit) => cubit.restore(),
    verify: (cubit) => expect(cubit.state, unticked),
  );

  blocTest<LegalConsentCubit, LegalConsentState>(
    'restore stays unticked when nothing is stored',
    build: build,
    act: (cubit) => cubit.restore(),
    verify: (cubit) => expect(cubit.state, unticked),
  );

  blocTest<LegalConsentCubit, LegalConsentState>(
    'accept ticks and remembers the current version (D-10)',
    build: build,
    act: (cubit) => cubit.accept(),
    expect: () => [ticked],
    verify: (_) => expect(store.acceptedVersion, version),
  );

  blocTest<LegalConsentCubit, LegalConsentState>(
    'withdraw unticks and forgets (D-10)',
    setUp: () => store.acceptedVersion = version,
    build: build,
    seed: () => ticked,
    act: (cubit) => cubit.withdraw(),
    expect: () => [unticked],
    verify: (_) => expect(store.acceptedVersion, isNull),
  );

  blocTest<LegalConsentCubit, LegalConsentState>(
    'forget unticks and clears the memory (D-10)',
    setUp: () => store.acceptedVersion = version,
    build: build,
    seed: () => ticked,
    act: (cubit) => cubit.forget(),
    expect: () => [unticked],
    verify: (_) => expect(store.acceptedVersion, isNull),
  );

  blocTest<LegalConsentCubit, LegalConsentState>(
    'a failing store keeps the tick for this screen and never throws',
    setUp: () => store.failOnRemember = true,
    build: build,
    act: (cubit) => cubit.accept(),
    expect: () => [ticked],
    errors: () => isEmpty,
  );

  test('nothing is emitted after close', () async {
    store.acceptedVersion = version;
    final cubit = build();
    final restoring = cubit.restore();
    await cubit.close();

    await expectLater(restoring, completes);
    expect(cubit.state, unticked);
  });
}
