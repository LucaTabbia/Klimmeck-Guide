import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/storage/legal_consent_store.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'legal_consent_state.dart';

/// Spunta del consenso legale sulla schermata di login (D-07, D-10).
///
/// La spunta è l'atto di accettazione su questo dispositivo (D-10): spuntare
/// ricorda la versione, togliere la spunta la dimentica. La memoria è diversa
/// da quella della sessione, quindi il logout non la tocca.
class LegalConsentCubit extends Cubit<LegalConsentState>
    with SafeEmit<LegalConsentState> {
  LegalConsentCubit(this._store, {required String version})
    : _version = version,
      super(const LegalConsentState());

  final LegalConsentStore _store;
  final String _version;

  /// Spuntata solo se la versione ricordata è quella corrente (D-12).
  Future<void> restore() async {
    final stored = await _readStoredVersion();
    emit(LegalConsentState(isAccepted: stored == _version));
  }

  Future<void> accept() async {
    emit(const LegalConsentState(isAccepted: true));
    await _guarded(() => _store.remember(_version));
  }

  Future<void> withdraw() async {
    emit(const LegalConsentState());
    await _guarded(_store.forget);
  }

  Future<String?> _readStoredVersion() async {
    try {
      return await _store.readAcceptedVersion();
    } catch (_) {
      return null;
    }
  }

  /// Uno storage guasto non toglie la spunta di questa schermata.
  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {}
  }
}
