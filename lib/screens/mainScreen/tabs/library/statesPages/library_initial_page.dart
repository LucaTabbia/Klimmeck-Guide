import 'package:flutter/material.dart';

import '../../../../../models/enums/library_book.dart';
import '../components/book_type.dart';
import '../components/library_book_art.dart';

class LibraryInitialPage extends StatelessWidget {
  const LibraryInitialPage({super.key, required this.onOpen});

  final ValueChanged<LibraryBook> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          _shelf([LibraryBook.bestiary, LibraryBook.places]),
          _shelf([LibraryBook.religions, LibraryBook.knowledge]),
        ],
      ),
    );
  }

  Widget _shelf(List<LibraryBook> books) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final book in books)
          BookType(
            title: book.title,
            imagePath: book.coverUrl,
            onTap: () => onOpen(book),
          ),
      ],
    );
  }
}
