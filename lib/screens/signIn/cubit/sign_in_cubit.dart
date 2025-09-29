import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

part 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  final KlimmeckGraphQl graphQl;

  SignInCubit(this.graphQl) : super(SignInInitial());
}
