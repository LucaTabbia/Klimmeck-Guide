import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../repository/services/api.dart';
import '../../../utils/queries_mutations.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this.api) : super(ProfileInitial());

  final Api api;

  Future<void> startManagement() async {
  }

  Future<void> logout() async {
    emit(ProfileLoading());
    try {
      var result = await api.performMutation(Query().logoutMutation);
      if (result.hasException) {
        print('graphQLErrors: ${result.exception?.graphqlErrors.toString()}');
        print('clientErrors: ${result.exception?.linkException.toString()}');
        emit(ProfileError(result.exception?.linkException.toString() ??
            result.exception?.graphqlErrors.toString() ??
            ""));
      } else {
        if (result.data!["logout"]["status"] == true) {
          emit(ProfileLogOut());
        } else {
          emit(ProfileError("Error during logout"));
        }
      }
    } catch (e) {
      print(e.toString());
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(ProfileLoading());
    try {
      var result = await api.performMutation(Query().resetPasswordMutation,
          variables: {"email": email});
      if (result.hasException) {
        print('graphQLErrors: ${result.exception?.graphqlErrors.toString()}');
        print('clientErrors: ${result.exception?.linkException.toString()}');
        emit(ProfileResetError(result.exception?.linkException.toString() ??
            result.exception?.graphqlErrors.toString() ??
            ""));
      } else {
        if (result.data!["resetPassword"]["status"] == true) {
          emit(ProfileReset());
        } else {
          emit(ProfileResetError("Error during reset"));
        }
      }
    } catch (e) {
      print(e.toString());
      emit(ProfileResetError(e.toString()));
    }
  }
}
