import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

abstract interface class BrowserAuthenticator {
  /// Apre [startUrl] nel browser di sistema e ritorna l'URL completo di callback.
  /// Lancia [BrowserAuthCancelled] o [BrowserAuthFailure].
  Future<String> authenticate({
    required Uri startUrl,
    required String callbackScheme,
  });
}

sealed class BrowserAuthException extends Equatable implements Exception {
  const BrowserAuthException();
}

final class BrowserAuthCancelled extends BrowserAuthException {
  const BrowserAuthCancelled();

  @override
  List<Object?> get props => [];
}

final class BrowserAuthFailure extends BrowserAuthException {
  const BrowserAuthFailure(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

BrowserAuthException mapBrowserAuthError(PlatformException error) =>
    error.code == 'CANCELED'
    ? const BrowserAuthCancelled()
    : BrowserAuthFailure(error.code);

class FlutterWebAuth2BrowserAuthenticator implements BrowserAuthenticator {
  const FlutterWebAuth2BrowserAuthenticator({this.preferEphemeral = false});

  final bool preferEphemeral;

  @override
  Future<String> authenticate({
    required Uri startUrl,
    required String callbackScheme,
  }) async {
    try {
      return await FlutterWebAuth2.authenticate(
        url: startUrl.toString(),
        callbackUrlScheme: callbackScheme,
        options: FlutterWebAuth2Options(preferEphemeral: preferEphemeral),
      );
    } on PlatformException catch (error) {
      throw mapBrowserAuthError(error);
    }
  }
}
