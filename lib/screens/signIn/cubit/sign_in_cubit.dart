import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/config/legal_documents.dart';
import 'package:klimmeck_guide/config/twitch_channel.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/login_exception.dart';
import 'package:klimmeck_guide/repository/services/links/link_opener.dart';

part 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._authTokenService, this._links) : super(const SignInIdle());

  final AuthTokenService _authTokenService;
  final LinkOpener _links;

  Future<void> signInWithTwitch() async {
    if (state is SignInInProgress) return;
    emit(const SignInInProgress());
    try {
      await _authTokenService.login();
      _emitIfOpen(const SignInIdle());
    } on LoginCancelledException {
      _emitIfOpen(const SignInIdle());
    } on LoginUnavailableException {
      _emitIfOpen(const SignInFailed(SignInFailure.twitchNotConfigured));
    } on LoginNotFollowingException {
      _emitIfOpen(const SignInFailed(SignInFailure.notFollowingChannel));
    } catch (_) {
      _emitIfOpen(const SignInFailed(SignInFailure.connection));
    }
  }

  Future<void> openChannel() => _links.open(TwitchChannel.uri);

  Future<void> openTerms() => _links.open(LegalDocuments.termsUri);

  Future<void> openPrivacy() => _links.open(LegalDocuments.privacyUri);

  void _emitIfOpen(SignInState next) {
    if (!isClosed) emit(next);
  }
}
