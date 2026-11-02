import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/request/equip_pet_request.dart';

void main() {
  test('EquipPetRequest serialises id and petId (D-16)', () {
    const request = EquipPetRequest(id: 'c-1', petId: 'pet-travel-horse');

    expect(request.toJson(), {'id': 'c-1', 'petId': 'pet-travel-horse'});
  });

  test('UnequipPetRequest serialises only the character id (D-16)', () {
    const request = UnequipPetRequest(id: 'c-1');

    expect(request.toJson(), {'id': 'c-1'});
  });

  test('requests are value-equal', () {
    expect(
      const EquipPetRequest(id: 'c-1', petId: 'pet-cat'),
      const EquipPetRequest(id: 'c-1', petId: 'pet-cat'),
    );
    expect(
      const EquipPetRequest(id: 'c-1', petId: 'pet-cat'),
      isNot(const EquipPetRequest(id: 'c-1', petId: 'pet-travel-horse')),
    );
    expect(
      const UnequipPetRequest(id: 'c-1'),
      const UnequipPetRequest(id: 'c-1'),
    );
    expect(
      const UnequipPetRequest(id: 'c-1'),
      isNot(const UnequipPetRequest(id: 'c-2')),
    );
  });
}
