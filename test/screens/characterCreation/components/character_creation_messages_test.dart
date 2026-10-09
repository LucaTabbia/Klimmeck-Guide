import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/race_traits.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/character_creation_messages.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_draft.dart';

void main() {
  const elf = RaceTraits(race: RaceType.elf, minAge: 100, maxAge: 9999);

  group('NameError.message', () {
    test('required has no text', () {
      expect(NameError.required.message, isNull);
    });

    test('maps the other errors to Italian copy', () {
      expect(NameError.tooShort.message, 'Il nome deve avere almeno 2 lettere');
      expect(
        NameError.tooLong.message,
        'Il nome può avere al massimo 20 caratteri',
      );
      expect(
        NameError.invalidCharacters.message,
        'Solo lettere, spazi, apostrofi e trattini',
      );
    });
  });

  group('ageErrorMessage', () {
    test('required has no text', () {
      expect(ageErrorMessage(AgeError.required, elf), isNull);
    });

    test('notANumber', () {
      expect(ageErrorMessage(AgeError.notANumber, elf), 'Inserisci un numero');
    });

    test('outOfRange names the race and the range', () {
      expect(
        ageErrorMessage(AgeError.outOfRange, elf),
        "Per la razza Elfo l'età va da 100 a 9999 anni",
      );
    });
  });

  test('every CharacterCreationFailure has a non-technical message', () {
    expect(
      CharacterCreationFailure.uploadFailed.message,
      'Caricamento del ritratto non riuscito, riprova',
    );
    expect(
      CharacterCreationFailure.nameInvalid.message,
      'Il nome non è accettato dalle cronache, scegline un altro',
    );
    expect(CharacterCreationFailure.nameTaken.message, 'Nome già in uso');
    expect(
      CharacterCreationFailure.ageOutOfRange.message,
      'Età non valida per la razza scelta',
    );
    expect(
      CharacterCreationFailure.alreadyExists.message,
      'Hai già un personaggio',
    );
    expect(
      CharacterCreationFailure.startingLocationUnavailable.message,
      'Il mondo non è ancora pronto ad accoglierti, riprova più tardi',
    );
    expect(
      CharacterCreationFailure.connection.message,
      'Errore di connessione, riprova',
    );
    expect(
      CharacterCreationFailure.unknown.message,
      'Qualcosa è andato storto, riprova',
    );
  });

  test('every PortraitPickFailure has a message', () {
    expect(
      PortraitPickFailure.permissionDenied.message,
      "Permesso negato: abilita l'accesso a foto e fotocamera dalle impostazioni",
    );
    expect(
      PortraitPickFailure.cameraUnavailable.message,
      'Nessuna fotocamera disponibile',
    );
    expect(
      PortraitPickFailure.unknown.message,
      'Impossibile usare questa immagine, riprova',
    );
  });

  test('backgroundTooLongMessage', () {
    expect(backgroundTooLongMessage, 'Massimo 500 caratteri');
  });
}
