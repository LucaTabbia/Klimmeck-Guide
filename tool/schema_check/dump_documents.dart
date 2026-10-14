import 'dart:io';

import 'schema_check_documents.dart';

/// Scrive un file `<operazione>.graphql` per documento in `args.single`.
///
/// Un file per documento: un file unico fallirebbe su "unique fragment name"
/// (`UserFields` ripetuto).
void main(List<String> args) {
  final outputDir = Directory(args.single)..createSync(recursive: true);
  schemaCheckDocuments.forEach((name, document) {
    File('${outputDir.path}/$name.graphql').writeAsStringSync(document);
  });
  stdout.writeln('dumped ${schemaCheckDocuments.length} documents');
}
