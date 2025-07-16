
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/storage/storage_manager.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../models/user.dart';
import '../../../repository/services/api.dart';
import '../../../utils/queries_mutations.dart';

part 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  final Api api;

  SignInCubit(this.api) : super(SignInInitial());

  void startLogIn(){
    emit(SignInForm());
  }

  Future<void> resetPassword(String email) async {
    emit(SignInLoading());
    try {
      var result = await api.performMutation(Query().resetPasswordMutation, variables: {"email": email});
      if (result.hasException) {
        print('graphQLErrors: ${result.exception?.graphqlErrors.toString()}');
        print('clientErrors: ${result.exception?.linkException.toString()}');
        emit(SignInResetError(result.exception?.linkException.toString() ??
            result.exception?.graphqlErrors.toString() ??
            ""));
      } else {
        if(result.data!["resetPassword"]["status"] == true) {
          emit(SignInReset());
        }else {
          emit(SignInResetError("Errore durante il recupero"));
        }

      }
    } catch (e) {
      print(e.toString());
      emit(SignInResetError("Errore durante il recupero"));
    }
  }

  Future<void> logIn(String email, String password) async {
    emit(SignInLoading());
    try {
      var deviceId = await KGStorageManager.getFirebaseToken();
      if (deviceId == null) {
        final status = await Permission.notification.status;
        if (status.isDenied || status.isPermanentlyDenied) {
          await openAppSettings();
        } else if (status.isGranted) {
          try {
            String? token = await FirebaseMessaging.instance.getToken();
            if (token != null && token != '') {
              await KGStorageManager.saveFirebaseToken(token);
              deviceId = token;
              FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
                await KGStorageManager.saveFirebaseToken(token);
              });
            }
          } catch (e) {
            throw Exception(e);
          }
        }
      }
      final result = await api.performQuery(Query().loginQuery, variables: {
        'email': email,
        'password': password,
        'device_id': null,
      });

      if (result.hasException) {
        if (result.exception?.graphqlErrors.first.extensions?["validation"]?["email"] != null) {
          emit(SignInError(
              "L'indirizzo e-mail e la password forniti non sono corretti, riprovare."));
        } else {
          emit(SignInError("Si è verificato un errore imprevisto, riprovare."));
        }
      } else {
        KGStorageManager.saveToken(result.data!["login"]["token"]);
        KGStorageManager.saveLoggedUser(User.fromJson(result.data!["login"]["user"]));
        KGStorageManager.saveUserLoggedCheck(true);
        await api.getClientWithBearer();
        try {
          final customerResult = await api.performQuery(Query().customersQuery);
          if (customerResult.hasException) {
            print('graphQLErrors: ${customerResult.exception?.graphqlErrors.toString()}');
            print('clientErrors: ${customerResult.exception?.linkException.toString()}');
            emit(SignInError(customerResult.exception?.linkException.toString() ??
                customerResult.exception?.graphqlErrors.toString() ??
                ""));
          } else {
            emit(SignInData());
          }
        } catch (e) {
          rethrow;
        }
        emit(SignInData());
      }
    } catch (e) {
      print(e);
      emit(SignInError(e.toString()));
    }
  }
}
