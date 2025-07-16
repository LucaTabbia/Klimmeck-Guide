import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../repository/services/api.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this.api) : super(SplashInitial());

  final Api api;


  Future<void> initializeLoggedUser() async {
    await api.getClientWithBearer();
  }
}
