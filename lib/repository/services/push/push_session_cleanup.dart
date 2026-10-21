/// Pulizia push prima del logout scelto dall'utente (D-08): `AuthCubit` la attende senza
/// conoscere i dettagli del push. Revoca e sync persa non passano di qui (nessun bearer valido).
abstract interface class PushSessionCleanup {
  Future<void> unregister();
}

/// Default quando il push non è cablato (test, composizioni parziali).
class NoPushSessionCleanup implements PushSessionCleanup {
  const NoPushSessionCleanup();

  @override
  Future<void> unregister() async {}
}
