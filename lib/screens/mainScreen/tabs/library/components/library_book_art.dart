import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Copertina, segnalibro e inchiostro del «Nuovo» di ogni libro (UI, D-07).
extension LibraryBookArt on LibraryBook {
  String get coverUrl => CloudinaryAssets.url(switch (this) {
    LibraryBook.bestiary => CloudinaryAssets.bestiary,
    LibraryBook.places => CloudinaryAssets.locations,
    LibraryBook.religions => CloudinaryAssets.religions,
    LibraryBook.knowledge => CloudinaryAssets.knowledge,
  });

  String get bookmarkUrl => CloudinaryAssets.url(switch (this) {
    LibraryBook.bestiary => CloudinaryAssets.bookmarkRed,
    LibraryBook.places => CloudinaryAssets.bookmarkGreen,
    LibraryBook.religions => CloudinaryAssets.bookmarkYellow,
    LibraryBook.knowledge => CloudinaryAssets.bookmarkBlue,
  });

  Color get newMarkInk => switch (this) {
    LibraryBook.bestiary => KlimmeckGuideTheme.royalCrimson,
    LibraryBook.places => KlimmeckGuideTheme.healGreen,
    LibraryBook.religions => KlimmeckGuideTheme.darkBronze,
    LibraryBook.knowledge => KlimmeckGuideTheme.mysticBlue,
  };
}
