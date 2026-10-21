import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/push_channel.dart';
import 'package:klimmeck_guide/config/twitch_channel.dart';

void main() {
  group('TwitchChannel', () {
    test('points at the streamer channel over https', () {
      expect(TwitchChannel.url, 'https://www.twitch.tv/lordreavor');
      expect(TwitchChannel.uri.scheme, 'https');
      expect(TwitchChannel.uri.host, 'www.twitch.tv');
    });
  });

  group('PushChannel', () {
    test('pins the Android channel and the small icon', () {
      expect(PushChannel.id, 'klimmeck_events');
      expect(PushChannel.name, 'Eventi di gioco');
      expect(PushChannel.smallIcon, 'ic_stat_klimmeck');
    });
  });
}
