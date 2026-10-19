import 'package:klimmeck_guide/repository/storage/device_identity_store.dart';

/// [DeviceIdentityStore] in memoria con id fisso e errore opzionale.
class InMemoryDeviceIdentityStore implements DeviceIdentityStore {
  String deviceId = 'device-1';
  int reads = 0;
  Object? failure;

  @override
  Future<String> readOrCreate() async {
    reads++;
    final error = failure;
    if (error != null) throw error;
    return deviceId;
  }
}
