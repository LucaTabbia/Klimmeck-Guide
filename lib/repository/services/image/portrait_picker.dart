enum PortraitSource { gallery, camera }

enum PortraitPickFailure { permissionDenied, cameraUnavailable, unknown }

class PortraitPickException implements Exception {
  const PortraitPickException(this.failure);

  final PortraitPickFailure failure;
}

/// Sceglie un ritratto dal dispositivo. Il file resta locale fino al submit (D-16).
abstract interface class PortraitPicker {
  /// Path locale dell'immagine già ridimensionata; null se l'utente annulla.
  /// Lancia [PortraitPickException] su permesso negato / fotocamera assente.
  Future<String?> pick(PortraitSource source);
}
