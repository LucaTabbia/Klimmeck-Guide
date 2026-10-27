import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/repository/quest_result_failure.dart';

const String questResultNoticeTitle = 'Risultato non disponibile';

/// Esito negativo della lettura per id dopo un tap (D-11): solo
/// NOT_FOUND/FORBIDDEN. Il `serial` crescente rende distinti due avvisi uguali.
class QuestResultNotice extends Equatable {
  const QuestResultNotice({
    required this.resultId,
    required this.failure,
    required this.serial,
  });

  final String resultId;
  final QuestResultFailure failure;
  final int serial;

  @override
  List<Object?> get props => [resultId, failure, serial];
}

/// Copy di dominio del banner (D-11), provvisoria (no UI phase). Gli errori di
/// rete restano muti: li copre la rilettura al resume.
KGNotification? questResultNoticeFor(QuestResultFailure failure) {
  final description = switch (failure) {
    QuestResultFailure.notFound => 'Questo risultato non esiste più',
    QuestResultFailure.forbidden => 'Questo risultato non ti appartiene',
    _ => null,
  };
  if (description == null) return null;
  return KGNotification(
    title: questResultNoticeTitle,
    description: description,
  );
}
