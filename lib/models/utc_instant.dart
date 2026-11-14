/// Istante servito in UTC; una data illeggibile vale `null` e il modello
/// che la contiene sopravvive.
DateTime? utcInstantOrNull(Object? json) =>
    json is String ? DateTime.tryParse(json)?.toUtc() : null;
