import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/storage/legal_consent_store.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'legal_consent_state.dart';

/// Spunta del consenso legale sulla schermata di login (D-07, D-10).
///
/// La spunta è l'atto di accettazione su questo dispositivo (D-10): spuntare
/// ricorda la versione, togliere la spunta la dimentica ([forget]). La memoria
/// è diversa da quella della sessione, quindi il logout non la tocca: oltre
/// alla spunta tolta, la dimentica solo l'account eliminato.
class LegalConsentCubit extends Cubit<LegalConsentState>
    with SafeEmit<LegalConsentState> {
  LegalConsentCubit(this._store, {required String version})
    : _version = version,
      super(const LegalConsentState());

  final LegalConsentStore _store;
  final String _version;
  bool _hasExplicitChoice = false;

  /// Spuntata solo se la versione ricordata è quella corrente (D-12). Una
  /// scelta arrivata mentre lo storage rispondeva vince sulla lettura.
  Future<void> restore() async {
    final stored = await _readStoredVersion();
    if (_hasExplicitChoice) return;
    emit(LegalConsentState(isAccepted: stored == _version));
  }

  Future<void> accept() async {
    _hasExplicitChoice = true;
    emit(const LegalConsentState(isAccepted: true));
    await _guarded(() => _store.remember(_version));
  }

  /// Spunta tolta o account eliminato (D-06, D-10): la casella è vuota e il
  /// dispositivo non ricorda più l'accettazione.
  Future<void> forget() async {
    _hasExplicitChoice = true;
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
