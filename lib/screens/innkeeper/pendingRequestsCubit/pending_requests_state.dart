part of 'pending_requests_cubit.dart';

/// Coda del GM per la route del pannello (10-CONTEXT D-10): l'ultima lista
/// valida resta finché un'altra la sostituisce; il loader solo prima del
/// primo snapshot.
final class PendingRequestsState extends Equatable {
  const PendingRequestsState({
    required this.serverNow,
    this.requests = const [],
    this.isLoaded = false,
    this.isForbidden = false,
    this.hiddenQuestIds = const {},
  });

  final List<PendingRequest> requests;
  final bool isLoaded;

  /// `FORBIDDEN` alla sottoscrizione o alla rilettura: il pannello si chiude
  /// (D-04).
  final bool isForbidden;
  final DateTime serverNow;

  /// Carte completate in attesa dello snapshot che le toglie (D-13, rimozione
  /// ottimistica).
  final Set<String> hiddenQuestIds;

  List<RequestCard> get cards =>
      requestCardsOf(requests, hiddenQuestIds: hiddenQuestIds);

  PendingRequestsState copyWith({
    List<PendingRequest>? requests,
    bool? isLoaded,
    bool? isForbidden,
    DateTime? serverNow,
    Set<String>? hiddenQuestIds,
  }) => PendingRequestsState(
    requests: requests ?? this.requests,
    isLoaded: isLoaded ?? this.isLoaded,
    isForbidden: isForbidden ?? this.isForbidden,
    serverNow: serverNow ?? this.serverNow,
    hiddenQuestIds: hiddenQuestIds ?? this.hiddenQuestIds,
  );

  @override
  List<Object?> get props => [
    requests,
    isLoaded,
    isForbidden,
    serverNow,
    hiddenQuestIds,
  ];
}
