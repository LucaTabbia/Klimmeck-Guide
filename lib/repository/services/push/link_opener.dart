/// Apre un link fuori dall'app (D-16). `false` se nessuna app lo gestisce.
abstract interface class LinkOpener {
  Future<bool> open(Uri uri);
}
