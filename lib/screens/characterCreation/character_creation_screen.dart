import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/race_traits.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/character_creation_messages.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/enum_choice_row.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/portrait_column.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/sheet_row.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/sheet_text_field.dart';
import 'package:klimmeck_guide/screens/characterCreation/components/submit_bar.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_creation_cubit.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_draft.dart';
import 'package:klimmeck_guide/shared/components/modal/logout_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Scheda di creazione del personaggio: utility screen (chrome ammesso), pagina
/// unica senza wizard (D-04); l'aspetto "scheda su pergamena" vince sul Material
/// di serie (D-06). Richiede [CharacterCreationCubit] e [AuthCubit] sopra di sé.
class CharacterCreationScreen extends StatelessWidget {
  const CharacterCreationScreen({super.key});

  static const int _portraitFlex = 2;
  static const int _sheetFlex = 5;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CharacterCreationCubit, CharacterCreationState>(
      listenWhen: (previous, current) =>
          previous.createdUser == null && current.createdUser != null,
      listener: _handOverCreatedUser,
      child: BlocBuilder<CharacterCreationCubit, CharacterCreationState>(
        builder: (context, state) => Scaffold(
          appBar: _buildAppBar(context, state),
          body: DecoratedBox(
            decoration: KlimmeckGuideTheme.getParchmentBackground(),
            child: SafeArea(child: _buildSheet(context, state)),
          ),
        ),
      ),
    );
  }

  /// D-02/D-26: la sessione adotta lo user creato; se lo rifiuta la scheda
  /// deve saperlo, altrimenti resterebbe bloccata senza uscita (D-29).
  void _handOverCreatedUser(
    BuildContext context,
    CharacterCreationState state,
  ) {
    final adopted = context.read<AuthCubit>().adoptUser(state.createdUser!);
    if (!adopted) context.read<CharacterCreationCubit>().handoverRejected();
  }

  AppBar _buildAppBar(BuildContext context, CharacterCreationState state) {
    final theme = KlimmeckGuideTheme.instance;
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Il tuo personaggio',
        style: theme.titleMedium.copyWith(
          color: KlimmeckGuideTheme.primaryGold,
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.canExit ? () => confirmLogout(context) : null,
          child: Text(
            'Esci',
            style: theme.bodyMedium.copyWith(
              color: KlimmeckGuideTheme.primaryGold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheet(BuildContext context, CharacterCreationState state) {
    final cubit = context.read<CharacterCreationCubit>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: _portraitFlex,
          child: PortraitColumn(
            portraitPath: state.portraitPath,
            pickFailure: state.pickFailure,
            enabled: !state.isSubmitting,
            onPick: cubit.pickPortrait,
            onRemove: cubit.removePortrait,
          ),
        ),
        Expanded(
          flex: _sheetFlex,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingLg),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._sheetRows(cubit, state),
                SubmitBar(
                  canSubmit: state.canSubmit,
                  isSubmitting: state.isSubmitting,
                  failure: state.submitFailure,
                  onSubmit: cubit.submit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _sheetRows(
    CharacterCreationCubit cubit,
    CharacterCreationState state,
  ) {
    final draft = state.draft;
    final enabled = !state.isSubmitting;
    return [
      SheetRow(
        label: 'Sesso',
        child: EnumChoiceRow<SexType>(
          values: SexType.values,
          selected: draft.sex,
          labelOf: (value) => value.label,
          onSelected: cubit.selectSex,
          enabled: enabled,
        ),
      ),
      SheetRow(
        label: 'Nome',
        child: SheetTextField(
          label: 'Nome',
          initialValue: draft.name,
          onChanged: cubit.updateName,
          errorText: state.nameError?.message,
          maxLength: CharacterDraft.nameMaxLength,
          enabled: enabled,
        ),
      ),
      SheetRow(
        label: 'Pronome',
        child: EnumChoiceRow<PronounType>(
          values: PronounType.values,
          selected: draft.pronoun,
          labelOf: (value) => value.label,
          onSelected: cubit.selectPronoun,
          enabled: enabled,
        ),
      ),
      SheetRow(
        label: 'Razza',
        child: EnumChoiceRow<RaceType>(
          values: RaceType.values,
          selected: draft.race,
          labelOf: (value) => value.label,
          onSelected: cubit.selectRace,
          enabled: enabled,
        ),
      ),
      SheetRow(
        label: 'Classe',
        child: EnumChoiceRow<ClassType>(
          values: ClassType.values,
          selected: draft.classType,
          labelOf: (value) => value.label,
          onSelected: cubit.selectClass,
          enabled: enabled,
        ),
      ),
      SheetRow(
        label: 'Età',
        child: _AgeField(cubit: cubit, state: state),
      ),
      SheetRow(
        label: 'Storia',
        child: SheetTextField(
          label: 'Storia',
          initialValue: draft.background,
          onChanged: cubit.updateBackground,
          hintText: 'Facoltativa: chi eri prima di arrivare a Klimmeck?',
          errorText: draft.isBackgroundTooLong
              ? backgroundTooLongMessage
              : null,
          minLines: 3,
          maxLines: 5,
          maxLength: CharacterDraft.backgroundMaxLength,
          enabled: enabled,
        ),
      ),
    ];
  }
}

class _AgeField extends StatelessWidget {
  const _AgeField({required this.cubit, required this.state});

  static const int _maxAgeDigits = 4;

  final CharacterCreationCubit cubit;
  final CharacterCreationState state;

  @override
  Widget build(BuildContext context) {
    final traits = state.selectedRaceTraits;
    final failed = state.raceTraitsStatus == RaceTraitsStatus.failed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetTextField(
          label: 'Età',
          initialValue: state.draft.ageText,
          onChanged: cubit.updateAge,
          enabled: state.isAgeEnabled && !state.isSubmitting,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(_maxAgeDigits),
          ],
          helperText: _helperText(traits),
          errorText: _errorText(traits),
        ),
        if (failed) _TraitsRetry(onRetry: cubit.loadRaceTraits),
      ],
    );
  }

  String? _helperText(RaceTraits? traits) {
    if (traits != null) return 'Tra ${traits.minAge} e ${traits.maxAge} anni';
    if (state.raceTraitsStatus == RaceTraitsStatus.failed) return null;
    if (state.draft.race == null) return 'Scegli prima la razza';
    return 'Consulto le cronache delle razze…';
  }

  String? _errorText(RaceTraits? traits) {
    final error = state.ageError;
    if (traits == null || error == null) return null;
    return ageErrorMessage(error, traits);
  }
}

class _TraitsRetry extends StatelessWidget {
  const _TraitsRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    return Row(
      children: [
        Flexible(
          child: Text(
            'Non riesco a leggere le età delle razze',
            style: theme.errorText,
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Riprova')),
      ],
    );
  }
}
