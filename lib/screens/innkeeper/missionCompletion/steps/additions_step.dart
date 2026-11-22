import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/mission_back_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/participant_story.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/shared/components/sheet_text_field.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Ultima pagina del flusso guidato (Phase 24 D-04..D-08): per partecipante
/// una tendina chiusa con la storia da rileggere e, sotto, un'aggiunta
/// facoltativa (D-23). I testi li possiede la schermata; ogni campo legge il
/// suo una volta sola, così una bozza appena servita non riscrive ciò che
/// l'oste sta scrivendo.
class AdditionsStep extends StatelessWidget {
  const AdditionsStep({
    super.key,
    required this.readers,
    required this.participants,
    required this.texts,
    required this.onChanged,
    required this.isSubmitting,
    required this.onConclude,
    required this.onRetry,
  });

  static const int maxAdditionLength = 1000;
  static const String fieldLabel = 'Aggiunta alla storia';
  static const String tooLongMessage = 'Massimo 1000 caratteri';
  static const String concludeLabel = 'Concludi';
  static const Key concludeKey = ValueKey('mission.additions.conclude');
  static const Key retryKey = ValueKey('mission.additions.retry');

  static Key fieldKeyFor(String characterId) =>
      ValueKey('mission.additions.field.$characterId');
  static Key summaryKeyFor(String characterId) =>
      ValueKey('mission.additions.summary.$characterId');

  /// Aiuto alla scrittura, non una validazione: il limite lo decide il BE
  /// (D-07), che conta i grafemi senza gli spazi ai bordi.
  static bool isTooLong(String text) => _lengthOf(text) > maxAdditionLength;

  /// Riassunto dell'aggiunta per l'intestazione della tendina (D-23); `null`
  /// per un campo che non aggiunge nulla (D-06).
  static String? summaryOf(String text) {
    if (_lengthOf(text) == 0) return null;
    return 'aggiunta ${counterOf(text)}';
  }

  /// Contatore del campo: lo stesso numero dell'intestazione, contato come
  /// il limite e non dal campo, che conterebbe anche gli spazi ai bordi.
  static String counterOf(String text) =>
      '${_lengthOf(text)}/$maxAdditionLength';

  static int _lengthOf(String text) => text.trim().characters.length;

  final List<StoryReader> readers;

  /// Le storie per id del personaggio, o la lettura fallita.
  final MissionParticipantsState participants;

  /// Testo scritto finora, per id del personaggio.
  final Map<String, String> texts;
  final void Function(String characterId, String text) onChanged;
  final bool isSubmitting;
  final VoidCallback onConclude;
  final VoidCallback onRetry;

  bool get _canConclude => !isSubmitting && !texts.values.any(isTooLong);

  @override
  Widget build(BuildContext context) {
    final loaded = switch (participants) {
      final MissionParticipantsLoaded loaded => loaded,
      _ => null,
    };
    final failureLine = switch (participants) {
      MissionParticipantsFailed(:final failure) =>
        MissionCompletionScreen.failureLineOf(failure),
      _ => null,
    };
    // con la tastiera aperta in orizzontale resta spazio solo per il campo che
    // si sta scrivendo: la riga dei pulsanti torna alla chiusura
    final isTyping = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (failureLine != null)
                  Text(
                    failureLine,
                    style: KlimmeckGuideTheme.instance.bodyMedium,
                  ),
                for (final reader in readers)
                  _ParticipantAddition(
                    reader: reader,
                    entries: loaded?.backgroundOf(reader.characterId),
                    pendingLine: failureLine ?? ParticipantStory.readingLine,
                    text: texts[reader.characterId] ?? '',
                    onChanged: (typed) => onChanged(reader.characterId, typed),
                  ),
              ],
            ),
          ),
        ),
        if (!isTyping)
          Row(
            children: [
              const MissionBackButton(),
              if (failureLine != null)
                TextButton(
                  key: retryKey,
                  onPressed: onRetry,
                  child: const Text(MissionCompletionScreen.retryLabel),
                ),
              const Spacer(),
              ElevatedButton(
                key: concludeKey,
                style: KlimmeckGuideTheme.primaryButtonStyle,
                onPressed: _canConclude ? onConclude : null,
                child: const Text(concludeLabel),
              ),
            ],
          ),
      ],
    );
  }
}

/// La tendina di un partecipante: storia e campo dell'aggiunta. Chiusa, tiene
/// vivo il campo con il suo testo ma gli toglie il fuoco, così non si scrive
/// in un campo che non si vede.
class _ParticipantAddition extends StatefulWidget {
  const _ParticipantAddition({
    required this.reader,
    required this.entries,
    required this.pendingLine,
    required this.text,
    required this.onChanged,
  });

  final StoryReader reader;
  final List<String>? entries;
  final String pendingLine;
  final String text;
  final ValueChanged<String> onChanged;

  @override
  State<_ParticipantAddition> createState() => _ParticipantAdditionState();
}

class _ParticipantAdditionState extends State<_ParticipantAddition> {
  static const int _fieldMinLines = 3;
  static const int _fieldMaxLines = 5;

  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final characterId = widget.reader.characterId;
    final isTooLong = AdditionsStep.isTooLong(widget.text);
    return ParticipantStory(
      reader: widget.reader,
      entries: widget.entries,
      pendingLine: widget.pendingLine,
      summary: _buildSummary(context, isTooLong: isTooLong),
      onToggle: () => setState(() => _isOpen = !_isOpen),
      below: ExcludeFocus(
        excluding: !_isOpen,
        child: SheetTextField(
          key: AdditionsStep.fieldKeyFor(characterId),
          label: AdditionsStep.fieldLabel,
          initialValue: widget.text,
          onChanged: widget.onChanged,
          minLines: _fieldMinLines,
          maxLines: _fieldMaxLines,
          counterText: AdditionsStep.counterOf(widget.text),
          errorText: isTooLong ? AdditionsStep.tooLongMessage : null,
        ),
      ),
    );
  }

  Widget? _buildSummary(BuildContext context, {required bool isTooLong}) {
    final summary = AdditionsStep.summaryOf(widget.text);
    if (summary == null) return null;
    final style = KlimmeckGuideTheme.instance.bodyMedium;
    return Text(
      summary,
      key: AdditionsStep.summaryKeyFor(widget.reader.characterId),
      style: isTooLong
          ? style.copyWith(color: Theme.of(context).colorScheme.error)
          : style,
    );
  }
}
