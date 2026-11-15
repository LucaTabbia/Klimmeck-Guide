import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/request/rename_pet_request.dart';

void main() {
  test('toJson carries the character id, the pet id and the name (D-23)', () {
    const request = RenamePetRequest(
      id: 'c-1',
      petId: 'pet-worg',
      name: 'Fenrir',
    );

    expect(request.toJson(), {
      'id': 'c-1',
      'petId': 'pet-worg',
      'name': 'Fenrir',
    });
  });

  test('requests are value-equal', () {
    expect(
      const RenamePetRequest(id: 'c-1', petId: 'pet-worg', name: 'Fenrir'),
      const RenamePetRequest(id: 'c-1', petId: 'pet-worg', name: 'Fenrir'),
    );
    expect(
      const RenamePetRequest(id: 'c-1', petId: 'pet-worg', name: 'Fenrir'),
      isNot(const RenamePetRequest(id: 'c-1', petId: 'pet-worg', name: 'Lupo')),
    );
  });
}
