
import 'package:graphql/client.dart';

import 'package:dio/dio.dart' as dio_http;
import 'package:klimmeck_guide/repository/storage/storage_manager.dart';


class Api {
  final dio = dio_http.Dio();

  static String userToken = '';
  static String baseUrl = '';
  static String webViewBaseUrl = '';
  static String testUrl = '';

  late String token;
  late AuthLink authLink;
  late HttpLink httpLink;
  late GraphQLClient client;

  Api() {
    httpLink = HttpLink("https://energialocale.bitboss.link/graphql");
    client = GraphQLClient(
      cache: GraphQLCache(),
      link: httpLink,
    );
  }

  Future<void> getClientWithBearer() async {
    token = await KGStorageManager.getToken();
    authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    Link link = authLink.concat(httpLink);

    client = GraphQLClient(
      cache: GraphQLCache(),
      link: link,
    );
  }

  Future<QueryResult> performQuery(String query,
      {Map<String, dynamic>? variables}) async {
    QueryOptions options =
    QueryOptions(document: gql(query), variables: variables ?? {});

    final result = await client.query(options);

    return result;
  }

  Future<QueryResult> performMutation(String query, {Map<String, dynamic>? variables}) async {
    MutationOptions options =
    MutationOptions(document: gql(query), variables: variables ?? {});

    final result = await client.mutate(options);

    return result;
  }



  ///FIREBASE
  /*Future<Map<String, String>> getHeaders() async {
    await checkFirebaseUserTokenExpired();

    String firebaseTokenInfoRefreshed = await ELStorageManager.getUserFirebaseToken();
    FirebaseUserTokenInfo infoObjectRefreshed =
    FirebaseUserTokenInfo.fromJson(jsonDecode(firebaseTokenInfoRefreshed));
    Api.userToken = infoObjectRefreshed.token;
    Map<String, String> headers = {"auth": Api.userToken, "Content-Type": "application/json"};
    print(Api.userToken);
    return headers;
  }

  Future<User?> signInWithApple() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final result = await TheAppleSignIn.performRequests([
        const AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);

      switch (result.status) {
        case AuthorizationStatus.authorized:
          try {
            final appleIdCredential = result.credential!;
            final oAuthProvider = OAuthProvider('apple.com');
            final credential = oAuthProvider.credential(
              idToken: String.fromCharCodes(appleIdCredential.identityToken!),
              accessToken: String.fromCharCodes(appleIdCredential.authorizationCode!),
            );

            final UserCredential authResult =
            await FirebaseAuth.instance.signInWithCredential(credential);

            final User? user = authResult.user;

            if (user != null && user.email != null) {
              assert(!user.isAnonymous);

              final User? currentUser = auth.currentUser;

              assert(user.uid == currentUser?.uid);
              return user;
            }
          } catch (e) {
            throw Exception('Errore login apple');
          }
          break;
        case AuthorizationStatus.error:
          throw Exception('Errore login apple');

        case AuthorizationStatus.cancelled:
          throw Exception('Errore login apple');
      }
    } catch (error) {
      throw Exception('Errore login apple');
    }
    return null;
  }

  Future<User?> signInWithGoogle() async {
    GoogleSignIn googleSignIn = GoogleSignIn();
    late GoogleSignInAccount? googleSignInAccount;
    late GoogleSignInAuthentication googleSignInAuthentication;
    final FirebaseAuth auth = FirebaseAuth.instance;

    googleSignIn = GoogleSignIn();

    await googleSignIn.signOut();
    googleSignInAccount = await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      googleSignInAuthentication = await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential authResult = await auth.signInWithCredential(credential);

      final User? user = authResult.user;

      if (user != null && user.email != null) {
        assert(!user.isAnonymous);

        final User? currentUser = auth.currentUser;

        assert(user.uid == currentUser?.uid);
        return user;
      } else {
        throw Exception('Errore login google');
      }
    }
    return null;
  }

  Future<User?> registerUser(String email, String password) async {
    final FirebaseAuth auth = FirebaseAuth.instance;

    try {
      final credentials = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credentials.user != null && credentials.user?.email != null) {
        credentials.user!.sendEmailVerification();
        return credentials.user;
      }
    } on FirebaseAuthException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final FirebaseAuth auth = FirebaseAuth.instance;

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user != null && user.email != null) {
        assert(!user.isAnonymous);

        final User? currentUser = auth.currentUser;

        assert(user.uid == currentUser?.uid);
        return user;
      }
    } on FirebaseAuthException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> refreshFirebaseUser() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      final user = auth.currentUser;
      final idTokenResult = await user!.getIdTokenResult(true);
      FirebaseUserTokenInfo userTokenInfo = FirebaseUserTokenInfo(
          token: idTokenResult.token!.toString(),
          expirationTime: idTokenResult.expirationTime.toString());
      await ELStorageManager.saveUserFirebaseToken(userTokenInfo);
    }
  }

  Future<void> checkFirebaseUserTokenExpired() async {
    String firebaseTokenInfo = await ELStorageManager.getUserFirebaseToken();
    if (firebaseTokenInfo == '') {
      await refreshFirebaseUser();
    } else {
      FirebaseUserTokenInfo infoObject =
      FirebaseUserTokenInfo.fromJson(jsonDecode(firebaseTokenInfo));

      DateTime now = DateTime.now();

      if (DateTime.parse(infoObject.expirationTime).isBefore(now)) {
        await refreshFirebaseUser();
      }
    }
  }*/
}