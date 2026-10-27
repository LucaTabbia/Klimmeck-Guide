import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/repository/quest_result_failure.dart';

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
