import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/quest_result_delivery_ports.dart';

void main() {
  test('NoPendingQuestResults has no pending result', () async {
    expect(await const NoPendingQuestResults().fetchUnacknowledged(), isEmpty);
  });

  test('NoQuestResultAcknowledger completes without doing anything', () {
    expect(const NoQuestResultAcknowledger().acknowledge('r-1'), completes);
  });
}
