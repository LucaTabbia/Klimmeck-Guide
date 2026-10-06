import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/login_exception.dart';

part 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._authTokenService) : super(const SignInIdle());

  final AuthTokenService _authTokenService;

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
    } catch (_) {
      _emitIfOpen(const SignInFailed(SignInFailure.connection));
    }
  }

  void _emitIfOpen(SignInState next) {
    if (!isClosed) emit(next);
  }
}
