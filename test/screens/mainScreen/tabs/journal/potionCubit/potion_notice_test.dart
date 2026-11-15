import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_notice.dart';

const String _generic = 'Qualcosa è andato storto, riprova';

void main() {
  group('potionNoticeFor', () {
    test('a recovery refusal says when the next potion is ready, from the '
        "server's remaining time (D-11, D-18)", () {
      expect(
        potionNoticeFor(
          ItemUseFailure.potionRecovering,
          remaining: const Duration(minutes: 72),
        ),
        const KGNotification(
          title: 'Pozione non bevuta',
          description:
              "Il tuo corpo non reggerebbe un'altra pozione: "
              'pronta fra 1 h 12 min',
        ),
      );
    });

    test('a recovery refusal without a remaining time is the generic notice '
        '(D-19)', () {
      for (final remaining in [
        null,
        Duration.zero,
        const Duration(minutes: -5),
      ]) {
        expect(
          potionNoticeFor(
            ItemUseFailure.potionRecovering,
            remaining: remaining,
          ),
          const KGNotification(
            title: 'Pozione non bevuta',
            description: _generic,
          ),
          reason: '$remaining',
        );
      }
    });

    test('a potion with no effect says so (D-11)', () {
      expect(
        potionNoticeFor(ItemUseFailure.noEffect),
        const KGNotification(
          title: 'Pozione non bevuta',
          description: 'Questa pozione non ti farebbe nulla adesso',
        ),
      );
    });

    test('a potion refused during a mission shows the wait line under '
        '«Pozione non bevuta» (D-30)', () {
      expect(
        potionNoticeFor(ItemUseFailure.missionInProgress),
        const KGNotification(
          title: 'Pozione non bevuta',
          description: "Sei impegnato in una missione: aspetta l'esito",
        ),
      );
    });

    test('every other refusal is the generic notice (D-11)', () {
      for (final failure in [
        ItemUseFailure.awaitingAid,
        ItemUseFailure.notOwned,
        ItemUseFailure.notUsable,
        ItemUseFailure.badUserInput,
        ItemUseFailure.connection,
        ItemUseFailure.timedOut,
        ItemUseFailure.unknown,
      ]) {
        expect(
          potionNoticeFor(failure),
          const KGNotification(
            title: 'Pozione non bevuta',
            description: _generic,
          ),
          reason: failure.name,
        );
      }
    });

    test('an unauthenticated refusal shows nothing (D-19)', () {
      expect(potionNoticeFor(ItemUseFailure.unauthenticated), isNull);
    });
  });

  group('potionNoticeFor with a companion target', () {
    test('a refused companion potion is titled «Pozione non data» '
        '(D-32)', () {
      expect(
        potionNoticeFor(ItemUseFailure.connection, targetName: 'Fulmine'),
        const KGNotification(title: 'Pozione non data', description: _generic),
      );
    });

    test('a defeated companion refuses with its name (D-06, D-20)', () {
      expect(
        potionNoticeFor(ItemUseFailure.petDefeated, targetName: 'Fulmine'),
        const KGNotification(
          title: 'Pozione non data',
          description:
              'Fulmine è sconfitto: solo il riposo lo rimette in forze',
        ),
      );
    });

    test('a companion in its own wait refuses with its name and the time '
        'left (D-05)', () {
      expect(
        potionNoticeFor(
          ItemUseFailure.petPotionRecovering,
          remaining: const Duration(minutes: 72),
          targetName: 'Fulmine',
        ),
        const KGNotification(
          title: 'Pozione non data',
          description:
              "Fulmine non reggerebbe un'altra pozione: pronta fra 1 h 12 min",
        ),
      );
      expect(
        potionNoticeFor(
          ItemUseFailure.petPotionRecovering,
          targetName: 'Fulmine',
        ),
        const KGNotification(title: 'Pozione non data', description: _generic),
      );
    });

    test('a companion at full life gets the no-effect line with its name '
        '(D-32)', () {
      expect(
        potionNoticeFor(ItemUseFailure.noEffect, targetName: 'Fulmine'),
        const KGNotification(
          title: 'Pozione non data',
          description: 'Questa pozione non farebbe nulla a Fulmine adesso',
        ),
      );
    });

    test('without a target the character copy is unchanged (Phase 18 '
        'D-11)', () {
      expect(
        potionNoticeFor(ItemUseFailure.noEffect),
        const KGNotification(
          title: 'Pozione non bevuta',
          description: 'Questa pozione non ti farebbe nulla adesso',
        ),
      );
      for (final failure in [
        ItemUseFailure.petDefeated,
        ItemUseFailure.petPotionRecovering,
      ]) {
        expect(
          potionNoticeFor(failure, remaining: const Duration(minutes: 5)),
          const KGNotification(
            title: 'Pozione non bevuta',
            description: _generic,
          ),
          reason: failure.name,
        );
      }
    });
  });
}
