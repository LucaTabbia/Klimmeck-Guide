import 'package:klimmeck_guide/repository/services/sync/sync_health.dart';

class RecordingSyncHealth implements SyncHealth {
  final List<String> calls = [];

  void clear() => calls.clear();

  @override
  void markHealthy(SyncSource source) => calls.add('healthy:${source.name}');

  @override
  void markDegraded(SyncSource source) => calls.add('degraded:${source.name}');

  @override
  void markTerminated(SyncSource source) =>
      calls.add('terminated:${source.name}');

  @override
  void release(SyncSource source) => calls.add('released:${source.name}');

  @override
  void touch() => calls.add('touch');
}
