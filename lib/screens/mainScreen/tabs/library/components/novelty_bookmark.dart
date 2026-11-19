import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/library_book_art.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

/// Targhetta «Novità» del colore del libro. L'immagine è quadrata con la
/// targhetta nella fascia centrale: qui se ne mostra solo quella fascia.
class NoveltyBookmark extends StatelessWidget {
  const NoveltyBookmark({super.key, required this.book, this.width = 90});

  static const double _bandAspectRatio = 2;

  final LibraryBook book;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width / _bandAspectRatio,
      child: ClipRect(
        child: OverflowBox(
          minHeight: width,
          maxHeight: width,
          child: CachedSvg(
            url: book.noveltyBookmarkUrl,
            width: width,
            height: width,
          ),
        ),
      ),
    );
  }
}
