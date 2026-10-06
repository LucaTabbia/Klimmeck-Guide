import 'package:equatable/equatable.dart';

const String loginCallbackScheme = 'klimmeck';
const String twitchNotConfiguredError = 'twitch_not_configured';

const String _accessDeniedError = 'access_denied';
const String _invalidCallbackError = 'invalid_callback';

sealed class LoginCallback extends Equatable {
  const LoginCallback();

  @override
  List<Object?> get props => [];
}

final class LoginTicketReceived extends LoginCallback {
  const LoginTicketReceived(this.ticket);

  final String ticket;

  @override
  List<Object?> get props => [ticket];

  @override
  bool get stringify => false;

  @override
  String toString() => 'LoginTicketReceived()';
}

final class LoginDeniedByUser extends LoginCallback {
  const LoginDeniedByUser();
}

final class LoginRejectedByBackend extends LoginCallback {
  const LoginRejectedByBackend(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

/// Parsa il deep link `klimmeck://auth?ticket=…|error=…` (input non fidato).
///
/// Totale: non lancia mai, ogni input anomalo diventa `invalid_callback`.
LoginCallback parseLoginCallback(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != loginCallbackScheme) {
    return const LoginRejectedByBackend(_invalidCallbackError);
  }
  final ticket = uri.queryParameters['ticket'];
  if (ticket != null && ticket.isNotEmpty) return LoginTicketReceived(ticket);

  final error = uri.queryParameters['error'];
  if (error == _accessDeniedError) return const LoginDeniedByUser();
  if (error != null && error.isNotEmpty) return LoginRejectedByBackend(error);

  return const LoginRejectedByBackend(_invalidCallbackError);
}
