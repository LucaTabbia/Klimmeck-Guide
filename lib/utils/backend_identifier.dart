final RegExp _backendIdentifierPattern = RegExp(r'^[A-Za-z0-9._-]{1,128}$');

/// Identificatore nell'alfabeto del backend (`[A-Za-z0-9._-]{1,128}`, lo stesso
/// di deviceId e id di evento), altrimenti `null`.
String? validBackendIdentifier(Object? value) =>
    value is String && _backendIdentifierPattern.hasMatch(value) ? value : null;
