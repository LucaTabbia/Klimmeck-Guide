import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/shared/components/background_entries.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Di chi è la storia: dalla scheda della richiesta prima della bozza, dalla
/// bozza dopo l'inizio della missione.
class StoryReader extends Equatable {
  const StoryReader({
    required this.characterId,
    required this.name,
    this.title,
  });

  StoryReader.ofParticipant(MissionParticipant participant)
    : this(
        characterId: participant.characterId,
        name: participant.name,
        title: participant.title,
      );

  final String characterId;
  final String name;

  /// `null` finché il rango non è noto.
  final TitleType? title;

  /// Intestazione della tendina del partecipante: nome e, se noto, rango.
  String get header {
    final title = this.title;
    if (title == null) return name;
    return '$name · ${title.label}';
  }

  @override
  List<Object?> get props => [characterId, name, title];
}

/// La storia di un partecipante in una tendina chiusa (D-03, D-08): mai un
/// popup (D-02a).
class ParticipantStory extends StatelessWidget {
  const ParticipantStory({
    super.key,
    required this.reader,
    required this.entries,
    required this.pendingLine,
  });

  static const String emptyLine =
      'Di questo avventuriero non si sa ancora nulla';
  static const String readingLine = 'Lettura della storia…';

  static Key keyFor(String characterId) =>
      ValueKey('mission.story.$characterId');

  final StoryReader reader;

  /// Voci nell'ordine servito; `null` finché la storia non è leggibile.
  final List<String>? entries;

  /// Riga mostrata al posto della storia non ancora leggibile.
  final String pendingLine;

  Widget get _story {
    final entries = this.entries;
    if (entries == null) return _line(pendingLine);
    if (entries.isEmpty) return _line(emptyLine);
    return BackgroundEntries(entries: entries);
  }

  Widget _line(String text) =>
      Text(text, style: KlimmeckGuideTheme.instance.bodyMedium);

  @override
  Widget build(BuildContext context) {
    return Dropdown(
      key: keyFor(reader.characterId),
      sectionName: reader.header,
      data: _story,
    );
  }
}
