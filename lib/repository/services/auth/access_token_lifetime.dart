import 'dart:convert';

/// Durata di un JWT (`exp - iat`) o `null` se il token non è decodificabile.
///
/// Decodifica solo il payload per lo scheduling; nessuna verifica di firma:
/// la sicurezza è del backend.
Duration? accessTokenLifetime(String jwt) {
  try {
    final segments = jwt.split('.');
    if (segments.length != 3) return null;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
    );
    if (payload is! Map<String, dynamic>) return null;
    final exp = payload['exp'];
    final iat = payload['iat'];
    if (exp is! num || iat is! num) return null;
    final seconds = exp.toInt() - iat.toInt();
    return seconds > 0 ? Duration(seconds: seconds) : null;
  } catch (_) {
    return null;
  }
}

/// Attesa prima del refresh proattivo: durata del token meno [margin], mai
/// sotto [floor] (anti-loop con clock del device sballato).
Duration refreshDelayFor({
  required String accessToken,
  required DateTime expiresAt,
  required DateTime now,
  Duration margin = const Duration(seconds: 60),
  Duration floor = const Duration(seconds: 30),
}) {
  final lifetime =
      accessTokenLifetime(accessToken) ?? expiresAt.difference(now);
  final delay = lifetime - margin;
  return delay < floor ? floor : delay;
}
