import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/request/participant_override.dart';

/// Input `CompletePendingRequestInput` (BE 09 §9): `outcomes` omesso quando nessuno è cambiato, il BE lascia intatti gli HP (D-11).
class CompletePendingRequestInput extends Equatable {
  const CompletePendingRequestInput({
    required this.pendingQuestId,
    required this.outcomes,
  });

  final String pendingQuestId;
  final List<ParticipantOverride> outcomes;

  Map<String, dynamic> toJson() => {
    'pendingQuestId': pendingQuestId,
    if (outcomes.isNotEmpty)
      'outcomes': [for (final outcome in outcomes) outcome.toJson()],
  };

  @override
  List<Object?> get props => [pendingQuestId, outcomes];
}
