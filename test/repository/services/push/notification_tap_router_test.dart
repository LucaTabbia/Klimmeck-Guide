import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/repository/services/push/notification_tap_router.dart';

import '../../../helpers/fakes/recording_link_opener.dart';
import '../../../helpers/fakes/recording_notification_intent_sink.dart';

void main() {
  late RecordingNotificationIntentSink sink;
  late RecordingLinkOpener links;
  late NotificationTapRouter router;

  final twitchChannel = Uri.parse('https://www.twitch.tv/lordreavor');

  NotificationIntent intentOf(NotificationCategory category, {String? id}) =>
      NotificationIntent(
        category: category,
        id: id,
        sentAt: DateTime.utc(2026, 10, 18, 12),
      );

  setUp(() {
    sink = RecordingNotificationIntentSink();
    links = RecordingLinkOpener();
    router = NotificationTapRouter(intents: sink, links: links);
  });

  test('a travelEnd tap is offered to the intent sink', () async {
    final intent = intentOf(NotificationCategory.travelEnd, id: 't-1');

    await router.handle(intent);

    expect(sink.offered, [intent]);
    expect(links.opened, isEmpty);
  });

  test('a questEnd tap is offered to the intent sink', () async {
    final intent = intentOf(NotificationCategory.questEnd, id: 'q-1');

    await router.handle(intent);

    expect(sink.offered, [intent]);
    expect(links.opened, isEmpty);
  });

  test('a streamerLive tap opens the Twitch channel only', () async {
    await router.handle(intentOf(NotificationCategory.streamerLive));

    expect(links.opened, [twitchChannel]);
    expect(sink.offered, isEmpty);
  });

  test('a Twitch link nobody handles completes without throwing', () async {
    links.result = false;

    await expectLater(
      router.handle(intentOf(NotificationCategory.streamerLive)),
      completes,
    );
    expect(sink.offered, isEmpty);
  });

  test('the payload id never chooses the opened URL', () async {
    await router.handle(
      intentOf(NotificationCategory.streamerLive, id: 'evil.example.com'),
    );

    expect(links.opened, [twitchChannel]);
  });
}
