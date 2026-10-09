import 'package:klimmeck_guide/models/character/race_traits.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_draft.dart';

const String backgroundTooLongMessage = 'Massimo 500 caratteri';

extension NameErrorMessage on NameError {
  /// Null quando il campo è solo vuoto: "Crea" resta disabilitato senza rimproveri.
  String? get message => switch (this) {
    NameError.required => null,
    NameError.tooShort => 'Il nome deve avere almeno 2 lettere',
    NameError.tooLong => 'Il nome può avere al massimo 20 caratteri',
    NameError.invalidCharacters => 'Solo lettere, spazi, apostrofi e trattini',
  };
}

String? ageErrorMessage(AgeError error, RaceTraits traits) => switch (error) {
  AgeError.required => null,
  AgeError.notANumber => 'Inserisci un numero',
  AgeError.outOfRange =>
    "Per la razza ${traits.race.label} l'età va da ${traits.minAge} a ${traits.maxAge} anni",
};

extension CharacterCreationFailureMessage on CharacterCreationFailure {
  String get message => switch (this) {
    CharacterCreationFailure.uploadFailed =>
      'Caricamento del ritratto non riuscito, riprova',
    CharacterCreationFailure.nameInvalid =>
      'Il nome non è accettato dalle cronache, scegline un altro',
    CharacterCreationFailure.nameTaken => 'Nome già in uso',
    CharacterCreationFailure.ageOutOfRange =>
      'Età non valida per la razza scelta',
    CharacterCreationFailure.alreadyExists => 'Hai già un personaggio',
    CharacterCreationFailure.startingLocationUnavailable =>
      'Il mondo non è ancora pronto ad accoglierti, riprova più tardi',
    CharacterCreationFailure.connection => 'Errore di connessione, riprova',
    CharacterCreationFailure.handoverRejected =>
      'Personaggio creato, ma la sessione non lo riconosce: esci e rientra',
    CharacterCreationFailure.unknown => 'Qualcosa è andato storto, riprova',
  };
}

extension PortraitPickFailureMessage on PortraitPickFailure {
  String get message => switch (this) {
    PortraitPickFailure.permissionDenied =>
      "Permesso negato: abilita l'accesso a foto e fotocamera dalle impostazioni",
    PortraitPickFailure.cameraUnavailable => 'Nessuna fotocamera disponibile',
    PortraitPickFailure.unknown => 'Impossibile usare questa immagine, riprova',
  };
}
