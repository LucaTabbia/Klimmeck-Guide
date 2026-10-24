import 'dart:async';
import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/repository/services/push/notification_tap_router.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'in_app_notifications_state.dart';

/// Banner in-app della shell (D-17/D-18): unico percorso di pubblicazione per
/// ogni produttore (FCM in foreground oggi, le subscription di Phase 7/9 domani).
/// Uno alla volta, in coda, chiusura automatica; un evento già visto nella
/// finestra di dedup non si ripete.
class InAppNotificationsCubit extends Cubit<InAppNotificationsState>
    with SafeEmit<InAppNotificationsState> {
  InAppNotificationsCubit({
    required Stream<PushEvent> events,
    required NotificationTapRouter router,
    DateTime Function() now = DateTime.now,
    Duration displayDuration = defaultDisplayDuration,
  }) : _router = router,
       _now = now,
       _displayDuration = displayDuration,
       super(const InAppNotificationsState()) {
    _subscription = events.listen(publish);
  }

  static const Duration defaultDisplayDuration = Duration(seconds: 5);
  static const Duration personalDedupWindow = Duration(minutes: 2);

  /// Pari al TTL del broadcast `streamerLive` lato backend (15 min). Vale per il
  /// tipo, non per il minuto di `sentAt`: una go-live produce un solo banner anche
  /// se push e subscription la consegnano con orari diversi.
  static const Duration streamerLiveDedupWindow = Duration(minutes: 15);

  final NotificationTapRouter _router;
  final DateTime Function() _now;
  final Duration _displayDuration;
  final Queue<Object> _queue = Queue<Object>();
  final Map<String, DateTime> _expiresAt = {};
  late final StreamSubscription<PushEvent> _subscription;
  Timer? _dismissTimer;

  /// Dopo `close()` non fa nulla: i produttori futuri (Phase 7/9) possono
  /// ancora chiamarlo, ma senza far crescere la coda né armare timer.
  void publish(PushEvent event) {
    if (isClosed) return;
    final now = _now();
    _expiresAt.removeWhere((_, expiry) => !now.isBefore(expiry));
    final key = _suppressionKeyOf(event);
    if (_expiresAt.containsKey(key)) return;
    _expiresAt[key] = now.add(_dedupWindowOf(event));
    _queue.add(event);
    if (!state.isShowing) _showNext();
  }

  /// Avviso locale (D-20 C1): stessa coda e stessa durata dei push; la finestra
  /// di dedup è la durata di visualizzazione.
  void publishNotice(KGNotification notification, {required String dedupKey}) {
    if (isClosed) return;
    final now = _now();
    _expiresAt.removeWhere((_, expiry) => !now.isBefore(expiry));
    final key = 'notice|$dedupKey';
    if (_expiresAt.containsKey(key)) return;
    _expiresAt[key] = now.add(_displayDuration);
    _queue.add(InAppNotice(notification: notification, dedupKey: dedupKey));
    if (!state.isShowing) _showNext();
  }

  /// Tap o chiusura: passa al prossimo in coda.
  void dismiss() => _showNext();

  /// Tap sul banner (D-17): stessa azione della notifica di sistema. La UI
  /// chiama solo questo metodo; il cubit chiude il banner e delega al router
  /// (UI → Cubit → Service, D-19). Un tap sul banner uscente durante la
  /// dissolvenza instrada solo il suo evento e lascia visibile quello corrente.
  Future<void> open(PushEvent event) async {
    if (state.current == event) dismiss();
    await _router.handle(event.intent);
  }

  void _showNext() {
    _dismissTimer?.cancel();
    if (isClosed) return;
    if (_queue.isEmpty) {
      emit(const InAppNotificationsState());
      return;
    }
    final next = _queue.removeFirst();
    emit(switch (next) {
      final PushEvent event => InAppNotificationsState(current: event),
      final InAppNotice notice => InAppNotificationsState(notice: notice),
      _ => const InAppNotificationsState(),
    });
    _dismissTimer = Timer(_displayDuration, _showNext);
  }

  static bool _isStreamerLive(PushEvent event) =>
      event.category == NotificationCategory.streamerLive;

  static String _suppressionKeyOf(PushEvent event) =>
      _isStreamerLive(event) ? event.category.wireType : event.dedupKey;

  static Duration _dedupWindowOf(PushEvent event) =>
      _isStreamerLive(event) ? streamerLiveDedupWindow : personalDedupWindow;

  /// `isClosed` è vero appena la shell rilascia il cubit: la cancellazione
  /// della subscription parte prima ma è attesa dopo `super.close()`.
  @override
  Future<void> close() async {
    _dismissTimer?.cancel();
    final cancelled = _subscription.cancel();
    await super.close();
    await cancelled;
  }
}
