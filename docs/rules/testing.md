# Testing

## Struttura

```
test/
├── <mirror di lib/>
│   ├── models/
│   ├── repository/
│   ├── screens/<feature>/
│   └── shared/components/
└── helpers/          # mock, fixture, test utils
```

Mirror la struttura di `lib/`. File test: `<target>_test.dart`.

## Livelli di test

### 1. Unit (models, utils, helper puri)

- Modelli: `fromJson`/`toJson` round-trip, `Equatable` props corretti, copyWith.
- Utils: ogni funzione pura.
- No dipendenze Flutter.

### 2. Cubit / BLoC (`bloc_test`)

- **Obbligatorio per ogni Cubit non triviale.**
- Un test per sequenza di stati attesa. Pattern:
  ```dart
  blocTest<CharacterCubit, CharacterState>(
    'emits [Loading, Loaded] when loadCharacter succeeds',
    build: () => CharacterCubit(mockRepo),
    act: (c) => c.loadCharacter(),
    expect: () => [CharacterLoading(), isA<CharacterLoaded>()],
  );
  ```
- Mock del Repository (`mocktail`). **Mai** colpire rete o GraphQL reale.
- Coprire: success path, error path, stati intermedi (accepting, submitting), side-effect su close.

### 3. Widget

- Per widget di `shared/components/` usato in ≥2 feature: test dedicato.
- Per screen/tab gameplay: smoke test (renderizza senza eccezioni con stato mock) + test di interazione chiave (swipe accept, tap travel confirm).
- Fornire `BlocProvider` con cubit mock (`MockCubit`) o `seeded` state.

### 4. Integration / end-to-end

- Non ora (v1.0). Pianificato post-hardening se si stabilizza un flow Twitch sandbox.

## Mocking

- Libreria: `mocktail` (preferita) — registra fallback per tipi custom.
- Mock Repository e Service layer. **Non** mockare BLoC che stai testando; mockalo solo quando è dipendenza di un altro componente.
- Fixture JSON per payload GraphQL in `test/helpers/fixtures/`.

## Regole

- **Un test fallisce per un motivo, non cinque.** Setup chiaro, assert mirato.
- **No test flaky tollerati.** Se è flaky, è rotto — investigare la race, non aggiungere retry.
- **Nessun `await Future.delayed` magico** per sincronizzare. Usare `pump`/`pumpAndSettle` o stream controllati.
- **`flutter analyze` pulito** prima di ogni commit. Warning = errore in PR review.
- Nuovo bug fix → test di regressione che falliva prima della fix.

## Comandi

```bash
flutter test                            # tutti i test
flutter test test/screens/mainScreen    # scope specifico
flutter test --coverage                 # genera coverage/lcov.info
```

## Copertura

- Target minimo non imposto, ma ogni Cubit e ogni modello devono avere test. Widget di gameplay critici (quest accept, travel confirm, combat outcome) devono avere almeno smoke + interaction.
