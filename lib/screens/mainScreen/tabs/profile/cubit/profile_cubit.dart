import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:meta/meta.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this.graphQl) : super(ProfileInitial());

  final KlimmeckGraphQl graphQl;
}
