import 'dart:async';

import 'package:klimmeck_guide/repository/quest_result_delivery_ports.dart';

/// Registra le conferme riuscite in [acknowledged] e ogni chiamata in [calls].
/// [error] fallisce sempre; [errorOnce] solo la prossima chiamata; con [hold]
/// la risposta aspetta il completer.
class RecordingQuestResultAcknowledger implements QuestResultAcknowledger {
  final List<String> acknowledged = [];
  final List<String> calls = [];
  Object? error;
  Object? errorOnce;
  Completer<void>? hold;

  @override
  Future<void> acknowledge(String resultId) async {
    calls.add(resultId);
    final gate = hold;
    if (gate != null) await gate.future;
    final once = errorOnce;
    if (once != null) {
      errorOnce = null;
      throw once;
    }
    final failure = error;
    if (failure != null) throw failure;
    acknowledged.add(resultId);
  }
}
