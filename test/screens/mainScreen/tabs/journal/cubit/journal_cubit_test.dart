import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/request/equip_item_request.dart';
import 'package:klimmeck_guide/repository/equipment_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';

void main() {
  late MockEquipmentRepository repository;
  final request = EquipItemRequest(
    id: 'c-1',
    itemId: 'e-1',
    slotType: SlotType.values.first,
  );

  setUpAll(() {
    registerFallbackValue(
      EquipItemRequest(
        id: 'c-1',
        itemId: 'e-1',
        slotType: SlotType.values.first,
      ),
    );
  });

  setUp(() => repository = MockEquipmentRepository());

  void refuseWith(EquipmentFailure failure) => when(
    () => repository.equip(any()),
  ).thenThrow(EquipmentException(failure));

  test('starts idle', () {
    expect(JournalCubit(repository).state, const JournalIdle());
  });

  blocTest<JournalCubit, JournalState>(
    'a successful equip emits nothing (the state arrives from '
    'characterUpdated)',
    build: () {
      when(() => repository.equip(any())).thenAnswer((_) async {});
      return JournalCubit(repository);
    },
    act: (cubit) => cubit.equipItem(request),
    expect: () => <JournalState>[],
    verify: (_) => verify(() => repository.equip(request)).called(1),
  );

  blocTest<JournalCubit, JournalState>(
    'a refusal emits JournalEquipRefused with the failure (LB-1)',
    build: () {
      refuseWith(EquipmentFailure.declined);
      return JournalCubit(repository);
    },
    act: (cubit) => cubit.equipItem(request),
    expect: () => const [
      JournalEquipRefused(failure: EquipmentFailure.declined, sequence: 1),
    ],
  );

  blocTest<JournalCubit, JournalState>(
    'two equal refusals emit two states with growing sequence (LB-1)',
    build: () {
      refuseWith(EquipmentFailure.connection);
      return JournalCubit(repository);
    },
    act: (cubit) async {
      await cubit.equipItem(request);
      await cubit.equipItem(request);
    },
    expect: () => const [
      JournalEquipRefused(failure: EquipmentFailure.connection, sequence: 1),
      JournalEquipRefused(failure: EquipmentFailure.connection, sequence: 2),
    ],
  );

  blocTest<JournalCubit, JournalState>(
    'MISSION_IN_PROGRESS reaches the state as missionInProgress (D-11)',
    build: () {
      refuseWith(EquipmentFailure.missionInProgress);
      return JournalCubit(repository);
    },
    act: (cubit) => cubit.equipItem(request),
    expect: () => const [
      JournalEquipRefused(
        failure: EquipmentFailure.missionInProgress,
        sequence: 1,
      ),
    ],
  );
}
