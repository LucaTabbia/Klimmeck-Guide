import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/character/awaiting_aid.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/pending_request/queued_travel.dart';
import 'package:klimmeck_guide/models/quest/adventurer_slot.dart';
import 'package:klimmeck_guide/models/quest/quest_capacity.dart';

/// Quest di una voce della coda del GM (selezione snella, 10-RESEARCH F3).
class PendingRequestQuest extends Equatable {
  const PendingRequestQuest({
    required this.id,
    required this.title,
    required this.type,
    required this.requiredAdventurers,
  });

  final String id;
  final String title;

  /// `null` per un tipo che il FE non conosce: la voce resta in coda.
  final QuestType? type;
  final List<AdventurerSlot> requiredAdventurers;

  int get totalSeats => totalSlots(requiredAdventurers);

  factory PendingRequestQuest.fromJson(Map<String, dynamic> json) =>
      PendingRequestQuest(
        id: json['id'] as String,
        title: json['title'] as String,
        type: QuestType.values.asNameMap()[json['type']],
        requiredAdventurers: AdventurerSlot.listFrom(
          json['requiredAdventurers'],
        ),
      );

  @override
  List<Object?> get props => [id, title, type, requiredAdventurers];
}

/// Personaggio di una voce della coda: posizione, viaggio libero, soccorso e corsia standard.
class PendingRequestCharacter extends Equatable {
  const PendingRequestCharacter({
    required this.id,
    required this.name,
    required this.locationId,
    required this.travel,
    required this.hasUnreadableTravel,
    required this.awaitingAid,
    required this.pendingQuestId,
  });

  final String id;
  final String name;

  /// Id del POI dove si trova (non popolato).
  final String? locationId;
  final QueuedTravel? travel;

  /// Un `activeTravel` presente ma illeggibile: fail-closed, mai «fermo» (C4).
  final bool hasUnreadableTravel;
  final AwaitingAid? awaitingAid;

  /// Corsia standard occupata (BE-HARD-08, BE Phase 10): opzionale finché il campo non è su develop (D-24); un personaggio impegnato non compare nella coda (D-07).
  final String? pendingQuestId;

  bool get isBusy => pendingQuestId != null;

  factory PendingRequestCharacter.fromJson(Map<String, dynamic> json) {
    final rawTravel = json['activeTravel'];
    final travel = QueuedTravel.tryFromJson(rawTravel);
    return PendingRequestCharacter(
      id: json['id'] as String,
      name: json['name'] as String,
      locationId: json['location'] as String?,
      travel: travel,
      hasUnreadableTravel: rawTravel != null && travel == null,
      awaitingAid: AwaitingAid.tryFromJson(json['awaitingAid']),
      pendingQuestId: json['pendingQuest'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    locationId,
    travel,
    hasUnreadableTravel,
    awaitingAid,
    pendingQuestId,
  ];
}

/// Voce della coda `pendingRequests` / `pendingRequestsUpdated` (BE 09 §9).
class PendingRequest extends Equatable {
  const PendingRequest({
    required this.id,
    required this.startDate,
    required this.quest,
    required this.character,
  });

  final String id;

  /// UTC.
  final DateTime? startDate;
  final PendingRequestQuest quest;
  final PendingRequestCharacter character;

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    final startDate = json['startDate'] as String?;
    return PendingRequest(
      id: json['id'] as String,
      startDate: startDate == null ? null : DateTime.parse(startDate).toUtc(),
      quest: PendingRequestQuest.fromJson(
        json['quest'] as Map<String, dynamic>,
      ),
      character: PendingRequestCharacter.fromJson(
        json['character'] as Map<String, dynamic>,
      ),
    );
  }

  /// Confine di parsing per voce (Phase 9 IN-04): una voce malformata vale `null` e il chiamante la salta, la lista sopravvive.
  static PendingRequest? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return PendingRequest.fromJson(json);
    } on Object {
      return null;
    }
  }

  @override
  List<Object?> get props => [id, startDate, quest, character];
}
