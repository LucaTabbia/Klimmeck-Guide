import 'package:flutter_bloc/flutter_bloc.dart';

/// Ignora gli `emit` arrivati dopo `close()`.
///
/// I Cubit gameplay vivono sotto `AuthenticatedShell` e vengono chiusi al
/// logout o al cambio account: una richiesta ancora in volo in quel momento
/// non deve lanciare `StateError` quando risponde.
mixin SafeEmit<S> on BlocBase<S> {
  @override
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }
}
