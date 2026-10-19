/// Canale Twitch dello streamer (Phase 5 D-16): unica URL che l'app apre da una
/// notifica. Non è un secret. Mai aprire URL presi dal payload.
class TwitchChannel {
  TwitchChannel._();

  static const String url = 'https://www.twitch.tv/lordreavor';

  static final Uri uri = Uri.parse(url);
}
