import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/pet_rename_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_notice.dart';

void main() {
  group('companionNameRefusalLine (D-31)', () {
    test('nameInvalid asks for another name (D-31)', () {
      expect(
        companionNameRefusalLine(PetRenameFailure.nameInvalid),
        'Il nome non è accettato dalle cronache, scegline un altro',
      );
    });

    test('connection asks to retry (D-31)', () {
      expect(
        companionNameRefusalLine(PetRenameFailure.connection),
        'Connessione assente, riprova',
      );
    });

    test('notOwned and notFound say the companion is gone (D-31)', () {
      for (final failure in [
        PetRenameFailure.notOwned,
        PetRenameFailure.notFound,
      ]) {
        expect(
          companionNameRefusalLine(failure),
          'Questo compagno non è più con te',
          reason: failure.name,
        );
      }
    });

    test('timedOut says the server did not answer (D-31)', () {
      expect(
        companionNameRefusalLine(PetRenameFailure.timedOut),
        'Il server non ha risposto in tempo, riprova',
      );
    });

    test('unauthenticated has no line (D-31)', () {
      expect(
        companionNameRefusalLine(PetRenameFailure.unauthenticated),
        isNull,
      );
    });

    test('forbidden says the character cannot do it, with no retry (D-31)', () {
      expect(
        companionNameRefusalLine(PetRenameFailure.forbidden),
        'Questo personaggio non può farlo',
      );
    });

    test('a refusal a retry cannot change offers no retry (D-31)', () {
      for (final failure in [
        PetRenameFailure.badUserInput,
        PetRenameFailure.refused,
      ]) {
        expect(
          companionNameRefusalLine(failure),
          'Qualcosa è andato storto',
          reason: failure.name,
        );
      }
    });

    test('a failure without a served code asks to retry (D-31)', () {
      for (final failure in [
        PetRenameFailure.declined,
        PetRenameFailure.unknown,
      ]) {
        expect(
          companionNameRefusalLine(failure),
          'Qualcosa è andato storto, riprova',
          reason: failure.name,
        );
      }
    });
  });
}
