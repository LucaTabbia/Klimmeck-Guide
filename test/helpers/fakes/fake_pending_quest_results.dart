import 'dart:async';

import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/quest_result_delivery_ports.dart';

/// Risultati non confermati scriptati: [results] o [error] a ogni chiamata;
/// con [hold] la risposta aspetta il completer (single-flight).
class FakePendingQuestResults implements PendingQuestResults {
  List<QuestResult> results = const [];
  Object? error;
  Completer<void>? hold;
  int calls = 0;

  @override
  Future<List<QuestResult>> fetchUnacknowledged() async {
    calls++;
    final gate = hold;
    if (gate != null) await gate.future;
    final failure = error;
    if (failure != null) throw failure;
    return results;
  }
}
