import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/mission_back_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/participant_story.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/shared/components/sheet_text_field.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Ultima pagina del flusso guidato (Phase 24 D-04..D-08): per partecipante la
/// storia da rileggere e un'aggiunta facoltativa. I testi li possiede la
/// schermata; ogni campo legge il suo una volta sola, così una bozza appena
/// servita non riscrive ciò che l'oste sta scrivendo.
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
  static const int _fieldMinLines = 3;
  static const int _fieldMaxLines = 5;

  static Key fieldKeyFor(String characterId) =>
      ValueKey('mission.additions.field.$characterId');

  /// Aiuto alla scrittura, non una validazione: il limite lo decide il BE
  /// (D-07), che conta i grafemi senza gli spazi ai bordi.
  static bool isTooLong(String text) =>
      text.trim().characters.length > maxAdditionLength;

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
                for (final reader in readers) ...[
                  ParticipantStory(
                    reader: reader,
                    entries: loaded?.backgroundOf(reader.characterId),
                    pendingLine: failureLine ?? ParticipantStory.readingLine,
                  ),
                  _additionField(reader.characterId),
                  const SizedBox(height: KlimmeckGuideTheme.spacingSm),
                ],
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

  Widget _additionField(String characterId) {
    final text = texts[characterId] ?? '';
    return SheetTextField(
      key: fieldKeyFor(characterId),
      label: fieldLabel,
      initialValue: text,
      onChanged: (typed) => onChanged(characterId, typed),
      minLines: _fieldMinLines,
      maxLines: _fieldMaxLines,
      maxLength: maxAdditionLength,
      errorText: isTooLong(text) ? tooLongMessage : null,
    );
  }
}
