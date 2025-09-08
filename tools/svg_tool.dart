import 'dart:io';

Future<void> cleanSvg() async {
  final dir = Directory('assets/icons');

  if (!await dir.exists()) {
    print("The directory doesn't exist");
    return;
  }

  final svgFiles = dir
      .listSync(recursive: true)
      .where((f) => f is File && f.path.endsWith('.svg'))
      .cast<File>();

  for (final file in svgFiles) {
    final content = await file.readAsString();

    final backupPath = '${file.path}.bak';
    if (!await File(backupPath).exists()) {
      await file.copy(backupPath);
    }

    final cleaned = content
        .replaceAll(RegExp(r'<defs\s*/>'), '')
        .replaceAll(RegExp(r'<defs>\s*</defs>'), '')
        .replaceAll(RegExp(r'<metadata[\s\S]*?</metadata>'), '')
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ');

    if (content != cleaned) {
      await file.writeAsString(cleaned);
      print('Cleaned: ${file.path}');
    } else {
      print('No changes: ${file.path}');
    }
  }

  print('Cleaning completed!');
}

Future<void> restoreSvgBackups() async {
  final dir = Directory('assets/icons');

  if (!await dir.exists()) {
    print("The directory doesn't exist");
    return;
  }

  final backupFiles = dir
      .listSync(recursive: true)
      .where((f) => f is File && f.path.endsWith('.svg.bak'))
      .cast<File>();

  for (final backup in backupFiles) {
    final originalPath = backup.path.replaceAll('.bak', '');
    await backup.copy(originalPath);
    print('Restored: $originalPath');
  }

  print('Recovery completed!');
}

Future<void> deleteSvgBackups() async {
  final dir = Directory('assets/icons');

  if (!await dir.exists()) {
    print("The directory doesn't exist");
    return;
  }

  final backupFiles = dir
      .listSync(recursive: true)
      .where((f) => f is File && f.path.endsWith('.svg.bak'))
      .cast<File>();

  for (final backup in backupFiles) {
    await backup.delete();
    print('Deleted: ${backup.path}');
  }

  print('Deleted all .bak files');
}

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart svg_tool.dart [clean|restore|delete]');
    return;
  }

  final command = args[0].toLowerCase();

  switch (command) {
    case 'clean':
      await cleanSvg();
      break;
    case 'restore':
      await restoreSvgBackups();
      break;
    case 'delete':
      await deleteSvgBackups();
      break;
    default:
      print('Unknown command: $command');
      print('Usage: dart svg_tool.dart [clean|restore|delete]');
  }
}
