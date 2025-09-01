String getStringToShowFromDuration(Duration duration) {
  return "${duration.inHours != 0 ? "${duration.inHours} ore" : ""} ${duration.inMinutes.remainder(60) != 0 ? ", ${duration.inMinutes.remainder(60)} minuti" : ""} ${duration.inSeconds.remainder(60) != 0 ? ", ${duration.inSeconds.remainder(60)} secondi" : ""}";
}
