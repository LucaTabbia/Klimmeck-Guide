import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:flutter/painting.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Copertine, nastro di ritorno, targhetta «Novità» e colore di ogni libro
/// (UI, D-07).
extension LibraryBookArt on LibraryBook {
  String get coverUrl => CloudinaryAssets.url(switch (this) {
    LibraryBook.bestiary => CloudinaryAssets.bestiary,
    LibraryBook.places => CloudinaryAssets.locations,
    LibraryBook.religions => CloudinaryAssets.religions,
    LibraryBook.knowledge => CloudinaryAssets.knowledge,
  });

  /// Il libro aperto sullo scaffale: contiene una novità.
  String get openCoverUrl => CloudinaryAssets.url(switch (this) {
    LibraryBook.bestiary => CloudinaryAssets.bestiaryOpen,
    LibraryBook.places => CloudinaryAssets.locationsOpen,
    LibraryBook.religions => CloudinaryAssets.religionsOpen,
    LibraryBook.knowledge => CloudinaryAssets.knowledgeOpen,
  });

  String get backBookmarkUrl => CloudinaryAssets.url(switch (this) {
    LibraryBook.bestiary => CloudinaryAssets.redBookmarkBack,
    LibraryBook.places => CloudinaryAssets.greenBookmarkBack,
    LibraryBook.religions => CloudinaryAssets.yellowBookmarkBack,
    LibraryBook.knowledge => CloudinaryAssets.blueBookmarkBack,
  });

  String get noveltyBookmarkUrl => CloudinaryAssets.url(switch (this) {
    LibraryBook.bestiary => CloudinaryAssets.redBookmark,
    LibraryBook.places => CloudinaryAssets.greenBookmark,
    LibraryBook.religions => CloudinaryAssets.yellowBookmark,
    LibraryBook.knowledge => CloudinaryAssets.blueBookmark,
  });

  /// Colore della linea sotto il titolo del libro.
  Color get ruleColor => switch (this) {
    LibraryBook.bestiary => KlimmeckGuideTheme.royalCrimson,
    LibraryBook.places => KlimmeckGuideTheme.healGreen,
    LibraryBook.religions => KlimmeckGuideTheme.darkBronze,
    LibraryBook.knowledge => KlimmeckGuideTheme.mysticBlue,
  };
}
