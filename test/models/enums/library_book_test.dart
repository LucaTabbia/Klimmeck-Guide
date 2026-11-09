import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';

void main() {
  test('lists the four books in the order of the shelf (D-06)', () {
    expect(LibraryBook.values, [
      LibraryBook.bestiary,
      LibraryBook.places,
      LibraryBook.religions,
      LibraryBook.knowledge,
    ]);
    expect(LibraryBook.values.map((book) => book.title), [
      'Bestiario',
      'Luoghi',
      'Religioni',
      'Conoscenze',
    ]);
  });

  test("keeps today's type mapping of every book (D-06)", () {
    expect(LibraryBook.bestiary.types, [
      LoreType.enemy,
      LoreType.animal,
      LoreType.plant,
    ]);
    expect(LibraryBook.places.types, [
      LoreType.city,
      LoreType.region,
      LoreType.state,
    ]);
    expect(LibraryBook.religions.types, [
      LoreType.religion,
      LoreType.ceremony,
      LoreType.god,
    ]);
    expect(LibraryBook.knowledge.types, [
      LoreType.character,
      LoreType.knowledge,
      LoreType.material,
    ]);
  });

  test('every lore type belongs to exactly one book (D-06)', () {
    for (final type in LoreType.values) {
      expect(
        LibraryBook.values.where((book) => book.holds(type)),
        hasLength(1),
        reason: type.name,
      );
    }
  });

  test('a typeless lore belongs to no book (D-16)', () {
    for (final book in LibraryBook.values) {
      expect(book.holds(null), isFalse);
    }
  });

  test('storage keys are stable and distinct (D-07)', () {
    expect(LibraryBook.values.map((book) => book.storageKey), [
      'bestiary',
      'places',
      'religions',
      'knowledge',
    ]);
  });
}
