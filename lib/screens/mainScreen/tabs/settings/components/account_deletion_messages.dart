import 'package:klimmeck_guide/repository/account_deletion_failure.dart';
import 'package:klimmeck_guide/utils/failure_lines.dart';

/// Copy di dominio per esito, mai testo del server (ui-ux.md).
extension AccountDeletionFailureMessage on AccountDeletionFailure {
  String get message => switch (this) {
    AccountDeletionFailure.connection => connectionFailureLine,
    AccountDeletionFailure.innkeeperProtected =>
      "L'oste non può eliminare il proprio account dall'App",
    AccountDeletionFailure.unauthenticated ||
    AccountDeletionFailure.unknown => accountDeletionFailedLine,
  };
}
