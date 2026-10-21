class PushMutations {
  /// Registra o aggiorna il device del chiamante (identità dal bearer, BE Phase 5 D-02).
  static const String registerPushDevice = r'''
    mutation RegisterPushDevice($input: RegisterPushDeviceInput!) {
      registerPushDevice(input: $input)
    }
  ''';

  /// Idempotente: true anche se il device non era registrato (BE D-03).
  static const String unregisterPushDevice = r'''
    mutation UnregisterPushDevice($deviceId: String!) {
      unregisterPushDevice(deviceId: $deviceId)
    }
  ''';
}
