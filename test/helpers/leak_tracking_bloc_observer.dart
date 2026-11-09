import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// I cubit non dispatchano eventi a leak_tracker (probe P-L2): questo observer,
/// solo di test, li rende visibili come `notDisposed` se non vengono chiusi (D-05).
class LeakTrackingBlocObserver extends BlocObserver {
  const LeakTrackingBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    LeakTracking.dispatchObjectCreated(
      library: 'package:bloc/bloc.dart',
      className: bloc.runtimeType.toString(),
      object: bloc,
    );
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    LeakTracking.dispatchObjectDisposed(object: bloc);
    super.onClose(bloc);
  }
}
