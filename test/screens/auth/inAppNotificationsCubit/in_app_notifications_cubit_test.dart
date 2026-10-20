import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/repository/services/push/notification_intent_sink.dart';
import 'package:klimmeck_guide/repository/services/push/notification_tap_router.dart';
import 'package:klimmeck_guide/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart';

import '../../../helpers/fakes/recording_link_opener.dart';
import '../../../helpers/fakes/recording_notification_intent_sink.dart';

void main() {
  final travelA = PushEvent(
    category: NotificationCategory.travelEnd,
    title: 'Viaggio completato',
    body: 'Il tuo personaggio è arrivato a destinazione.',
    sentAt: DateTime.utc(2026, 10, 18, 12),
    id: 'travel-a',
  );
  final travelB = PushEvent(
    category: NotificationCategory.travelEnd,
    title: 'Viaggio completato',
    body: 'Un altro viaggio è terminato.',
    sentAt: DateTime.utc(2026, 10, 18, 12, 1),
    id: 'travel-b',
  );
  final questA = PushEvent(
    category: NotificationCategory.questEnd,
    title: 'Quest completata',
    body: 'La tua quest si è conclusa.',
    sentAt: DateTime.utc(2026, 10, 18, 12, 2),
    id: 'quest-a',
  );
  final streamerLive = PushEvent(
    category: NotificationCategory.streamerLive,
    title: 'Lo streamer è in live',
    body: 'Unisciti alla diretta.',
    sentAt: DateTime.utc(2026, 10, 18, 12, 0, 42),
  );

  late RecordingNotificationIntentSink sink;
  late RecordingLinkOpener links;

  setUp(() {
    sink = RecordingNotificationIntentSink();
    links = RecordingLinkOpener();
  });

  void withCubit(
    void Function(
      FakeAsync async,
      InAppNotificationsCubit cubit,
      StreamController<PushEvent> events,
    )
    body, {
    NotificationIntentSink? intents,
  }) {
    fakeAsync((async) {
      final clock = async.getClock(DateTime.utc(2026, 10, 18, 12));
      final events = StreamController<PushEvent>();
      final cubit = InAppNotificationsCubit(
        events: events.stream,
        router: NotificationTapRouter(intents: intents ?? sink, links: links),
        now: clock.now,
      );
      body(async, cubit, events);
      cubit.close();
      events.close();
      async.flushMicrotasks();
    });
  }

  test('starts without a banner', () {
    withCubit((async, cubit, events) {
      expect(cubit.state, const InAppNotificationsState());
      expect(cubit.state.current, isNull);
    });
  });

  test('shows a published event for five seconds', () {
    withCubit((async, cubit, events) {
      cubit.publish(travelA);
      expect(cubit.state.current, travelA);

      async.elapse(const Duration(milliseconds: 4999));
      expect(cubit.state.current, travelA);

      async.elapse(const Duration(milliseconds: 1));
      expect(cubit.state.current, isNull);
    });
  });

  test('shows queued events one at a time in order', () {
    withCubit((async, cubit, events) {
      cubit
        ..publish(travelA)
        ..publish(questA);
      expect(cubit.state.current, travelA);

      async.elapse(const Duration(seconds: 5));
      expect(cubit.state.current, questA);

      async.elapse(const Duration(seconds: 5));
      expect(cubit.state.current, isNull);
    });
  });

  test('dismiss shows the next event with a fresh timer', () {
    withCubit((async, cubit, events) {
      cubit
        ..publish(travelA)
        ..publish(questA);
      async.elapse(const Duration(seconds: 3));

      cubit.dismiss();
      expect(cubit.state.current, questA);

      async.elapse(const Duration(milliseconds: 4999));
      expect(cubit.state.current, questA);
      async.elapse(const Duration(milliseconds: 1));
      expect(cubit.state.current, isNull);
    });
  });

  test('drops a personal duplicate within two minutes', () {
    withCubit((async, cubit, events) {
      cubit.publish(travelA);
      async.elapse(const Duration(seconds: 6));

      cubit.publish(travelA);
      expect(cubit.state.current, isNull);

      async.elapse(const Duration(minutes: 2));
      async.elapse(const Duration(seconds: 1));
      cubit.publish(travelA);
      expect(cubit.state.current, travelA);
    });
  });

  test('drops a streamerLive of the same minute within fifteen minutes', () {
    withCubit((async, cubit, events) {
      cubit.publish(streamerLive);
      async.elapse(const Duration(minutes: 10));

      cubit.publish(streamerLive);
      expect(cubit.state.current, isNull);

      async.elapse(const Duration(minutes: 5));
      cubit.publish(streamerLive);
      expect(cubit.state.current, streamerLive);
    });
  });

  test('shows events of the same type with different ids', () {
    withCubit((async, cubit, events) {
      cubit
        ..publish(travelA)
        ..publish(travelB);
      expect(cubit.state.current, travelA);

      async.elapse(const Duration(seconds: 5));
      expect(cubit.state.current, travelB);
    });
  });

  test('publishes the events of the stream with the same dedup', () {
    withCubit((async, cubit, events) {
      events
        ..add(travelA)
        ..add(travelA)
        ..add(questA);
      async.flushMicrotasks();
      expect(cubit.state.current, travelA);

      async.elapse(const Duration(seconds: 5));
      expect(cubit.state.current, questA);

      async.elapse(const Duration(seconds: 5));
      expect(cubit.state.current, isNull);
    });
  });

  test('close cancels the timer and the subscription', () {
    fakeAsync((async) {
      final events = StreamController<PushEvent>.broadcast();
      final emitted = <InAppNotificationsState>[];
      final cubit = InAppNotificationsCubit(
        events: events.stream,
        router: NotificationTapRouter(intents: sink, links: links),
      );
      cubit.stream.listen(emitted.add);
      cubit.publish(travelA);
      async.flushMicrotasks();

      cubit.close();
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);
      expect(events.hasListener, isFalse);

      events.add(questA);
      async.elapse(const Duration(seconds: 10));
      expect(emitted, [InAppNotificationsState(current: travelA)]);
      events.close();
    });
  });

  test('open on a personal event lands on the map and shows the next', () {
    withCubit((async, cubit, events) {
      cubit
        ..publish(travelA)
        ..publish(questA);

      cubit.open(travelA);
      async.flushMicrotasks();

      expect(sink.offered.single, travelA.intent);
      expect(links.opened, isEmpty);
      expect(cubit.state.current, questA);
    });
  });

  test('open on streamerLive opens Twitch and dismisses the banner', () {
    withCubit((async, cubit, events) {
      cubit.publish(streamerLive);

      cubit.open(streamerLive);
      async.flushMicrotasks();

      expect(
        links.opened.single,
        Uri.parse('https://www.twitch.tv/lordreavor'),
      );
      expect(sink.offered, isEmpty);
      expect(cubit.state.current, isNull);
    });
  });

  test('open on an outgoing banner routes it and keeps the current one', () {
    withCubit((async, cubit, events) {
      cubit
        ..publish(travelA)
        ..publish(questA)
        ..dismiss();
      expect(cubit.state.current, questA);

      cubit.open(travelA);
      async.flushMicrotasks();

      expect(sink.offered.single, travelA.intent);
      expect(cubit.state.current, questA);
    });
  });

  test('open dismisses the banner before routing', () {
    late InAppNotificationsCubit observed;
    final probe = _StateProbeSink(() => observed.state.current);
    withCubit((async, cubit, events) {
      observed = cubit;
      cubit.publish(travelA);

      cubit.open(travelA);
      async.flushMicrotasks();

      expect(probe.currentAtOffer, [null]);
    }, intents: probe);
  });
}

class _StateProbeSink implements NotificationIntentSink {
  _StateProbeSink(this._current);

  final PushEvent? Function() _current;
  final List<PushEvent?> currentAtOffer = [];

  @override
  void offer(NotificationIntent intent) => currentAtOffer.add(_current());
}
