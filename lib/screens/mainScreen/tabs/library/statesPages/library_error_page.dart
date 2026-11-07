import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_book_frame.dart';

import '../../../../../models/enums/library_book.dart';
import '../../../../../theme/kg_theme.dart';

/// Apertura fallita (D-06): la pergamena del libro con una sola riga, mai il
/// messaggio del server; il segnalibro riporta agli scaffali.
class LibraryErrorPage extends StatelessWidget {
  const LibraryErrorPage({super.key, required this.book, required this.onBack});

  static const String errorLine =
      'Le pagine di questo libro sono sbiadite. Riprova più tardi.';
  static const Key errorKey = ValueKey('library.error');

  final LibraryBook book;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LibraryBookFrame(
      book: book,
      onBack: onBack,
      child: Text(
        errorLine,
        key: errorKey,
        textAlign: TextAlign.center,
        style: KlimmeckGuideTheme.instance.bodyMedium,
      ),
    );
  }
}
