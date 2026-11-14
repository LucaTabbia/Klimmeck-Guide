import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/mission_back_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/completion_exit.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/enemy_search_bar.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/mission_step_header.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/encounters_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/fight_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/place_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/prizes_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/recap_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/start_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Pagine del wizard: navigazione locale, mai salvata (la bozza servita tiene
/// il passo, D-09).
enum MissionPage { place, encounters, fight, prizes, recap }

/// Completamento guidato della missione (D-09, D-11, D-28): utility screen
/// sopra la bozza servita. Esce con un [CompletionExit] come il form di
/// Phase 10. Richiede sopra di sé [MissionDraftCubit],
/// [MissionParticipantsCubit], [MissionEnemiesCubit], [MissionPrizeOptionsCubit],
/// [PendingRequestsCubit] e [TeleportModeCubit].
class MissionCompletionScreen extends StatefulWidget {
  const MissionCompletionScreen({
    super.key,
    required this.card,
    this.opensAtPlace = false,
  });

  static const String title = 'Completa la missione';
  static const String startLabel = 'Inizia la missione';
  static const String startNote =
      "Da ora i partecipanti non possono viaggiare, accettare missioni, comprare o cambiare equipaggiamento fino all'esito";
  static const String leaveNote =
      'La bozza resta salvata: puoi riprenderla dalla Locanda';
  static const String discardLabel = 'Scarta la bozza';
  static const String discardTitle = 'Scartare la bozza?';
  static const String discardBody =
      'I partecipanti tornano liberi; il teletrasporto resta.';
  static const String backLabel = MissionBackButton.label;
  static const String nextLabel = 'Avanti';
  static const String retryLabel = 'Riprova';
  static const String placeTitle = 'Luogo';
  static const String encountersTitle = 'Scontri';
  static const String prizesTitle = 'Premi';
  static const String recapTitle = 'Riepilogo';
  static String fightTitle(int index, int count) =>
      'Scontro ${index + 1} di $count';
  static const String invalidValuesMessage =
      'Operazione rifiutata: controlla scontri, correzioni e premi';
  static const String notParticipantMessage =
      'Un partecipante non fa più parte della richiesta';
  static const String connectionMessage = 'Connessione assente, riprova';
  static const String genericMessage = 'Qualcosa è andato storto, riprova';
  static const Key startKey = ValueKey('mission.start');
  static const Key discardKey = ValueKey('mission.discard');
  static const Key backKey = MissionBackButton.buttonKey;
  static const Key nextKey = ValueKey('mission.next');
  static const Key retryKey = ValueKey('mission.retry');

  /// Riga d'errore del wizard per un rifiuto o una lettura fallita.
  static String failureLineOf(InnkeeperFailure failure) => switch (failure) {
    InnkeeperFailure.overrideInvalid => invalidValuesMessage,
    InnkeeperFailure.notParticipant => notParticipantMessage,
    InnkeeperFailure.connection => connectionMessage,
    _ => genericMessage,
  };

  final RequestCard card;

  /// Dopo un teletrasporto annullato l'oste torna a «Luogo», da dove era
  /// partito, qualunque sia il passo servito (UAT 2026-11-14).
  final bool opensAtPlace;

  @override
  State<MissionCompletionScreen> createState() =>
      _MissionCompletionScreenState();
}

class _MissionCompletionScreenState extends State<MissionCompletionScreen> {
  MissionPage _page = MissionPage.place;
  int _fightIndex = 0;
  bool _hasLeft = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<MissionDraftCubit>().state;
    if (state is MissionDraftReady) _openServedStep(state.draft);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PendingRequestsCubit, PendingRequestsState>(
          listenWhen: (_, current) => _isRequestGone(current),
          listener: (_, _) => _leave(const CompletionGone()),
        ),
        BlocListener<MissionDraftCubit, MissionDraftState>(
          listenWhen: (previous, current) =>
              previous is! MissionDraftReady && current is MissionDraftReady,
          listener: (_, state) => setState(
            () => _openServedStep((state as MissionDraftReady).draft),
          ),
        ),
        BlocListener<MissionDraftCubit, MissionDraftState>(
          listenWhen: _isExitOrNewFailure,
          listener: _onDraftOutcome,
        ),
        BlocListener<TeleportModeCubit, TeleportModeState>(
          listenWhen: (previous, current) =>
              current is TeleportPreparationFailed && previous != current,
          listener: (context, _) => _showSnackBar(
            context,
            InnkeeperPanelScreen.teleportUnavailableMessage,
          ),
        ),
      ],
      child: BlocBuilder<MissionDraftCubit, MissionDraftState>(
        builder: (context, state) => PopScope(
          canPop: !_isCallInFlight(state),
          child: _buildScaffold(context, state),
        ),
      ),
    );
  }

  /// Pitfall 5: conta la coda grezza, non le carte azionabili.
  bool _isRequestGone(PendingRequestsState state) =>
      state.isLoaded && !state.requests.any(_belongsToCard);

  bool _belongsToCard(PendingRequest request) =>
      widget.card.questType == QuestType.worldMission
      ? request.quest.id == widget.card.questId
      : request.id == widget.card.pendingQuestId;

  /// Il passo servito sceglie la pagina solo alla prima bozza letta o creata
  /// (D-18): i salvataggi successivi non spostano l'oste.
  void _openServedStep(MissionDraft draft) {
    final page = widget.opensAtPlace ? MissionPage.place : _pageOf(draft.step);
    _enter(page);
    _loadParticipants(draft);
    if (page == MissionPage.recap) _loadPrizeNames(_characterIdsOf(draft));
  }

  void _loadParticipants(MissionDraft draft) =>
      context.read<MissionParticipantsCubit>().load(_characterIdsOf(draft));

  static List<String> _characterIdsOf(MissionDraft draft) => [
    for (final participant in draft.participants) participant.characterId,
  ];

  /// «Premi» legge le opzioni da sé; un «Riepilogo» riaperto le chiede qui
  /// per dare un nome ai premi scelti (D-22).
  void _loadPrizeNames(List<String> characterIds) =>
      context.read<MissionPrizeOptionsCubit>().loadAll(characterIds);

  /// Unico punto in cui la pagina cambia: «Scontri» chiede la lista dei
  /// nemici solo se non c'è ancora (D-03).
  void _enter(MissionPage page, {int fightIndex = 0}) {
    _page = page;
    _fightIndex = fightIndex;
    if (page == MissionPage.encounters) _loadEnemiesIfMissing();
  }

  void _loadEnemiesIfMissing() {
    final enemies = context.read<MissionEnemiesCubit>();
    if (enemies.state.enemies.isNotEmpty || enemies.state.isLoading) return;
    enemies.load();
  }

  static MissionPage _pageOf(MissionDraftStep? step) => switch (step) {
    MissionDraftStep.fights => MissionPage.encounters,
    MissionDraftStep.prizes => MissionPage.prizes,
    MissionDraftStep.recap => MissionPage.recap,
    MissionDraftStep.teleport || null => MissionPage.place,
  };

  static bool _isCallInFlight(MissionDraftState state) => switch (state) {
    MissionDraftReady(:final isSubmitting) => isSubmitting,
    MissionDraftAbsent(:final isStarting) => isStarting,
    _ => false,
  };

  static int? _failureSerialOf(MissionDraftState state) => switch (state) {
    MissionDraftReady(:final failureSerial) => failureSerial,
    MissionDraftAbsent(:final failureSerial) => failureSerial,
    _ => null,
  };

  static bool _isExitOrNewFailure(
    MissionDraftState previous,
    MissionDraftState current,
  ) => switch (current) {
    MissionDraftReady(failure: _?) || MissionDraftAbsent(failure: _?) =>
      _failureSerialOf(previous) != _failureSerialOf(current),
    MissionDraftCompleted() ||
    MissionDraftDiscarded() ||
    MissionDraftLoadFailed() => true,
    _ => false,
  };

  void _onDraftOutcome(BuildContext context, MissionDraftState state) {
    switch (state) {
      case MissionDraftCompleted(:final results):
        _leave(CompletionCompleted(results));
      case MissionDraftDiscarded():
        _leave(null);
      case MissionDraftLoadFailed(:final failure):
        final exit = _exitOf(failure);
        if (exit != null) _leave(exit);
      case MissionDraftReady(:final failure?) ||
          MissionDraftAbsent(:final failure?):
        final exit = _exitOf(failure);
        if (exit != null) return _leave(exit);
        _showSnackBar(context, MissionCompletionScreen.failureLineOf(failure));
      case MissionDraftReady() || MissionDraftAbsent() || MissionDraftLoading():
        return;
    }
  }

  /// D-25: NOT_FOUND toglie la carta, QUEST_IN_PROGRESS rilegge la coda,
  /// FORBIDDEN chiude il pannello; gli altri codici restano nel wizard.
  static CompletionExit? _exitOf(InnkeeperFailure failure) => switch (failure) {
    InnkeeperFailure.notFound => const CompletionGone(),
    InnkeeperFailure.questInProgress => const CompletionBusy(),
    InnkeeperFailure.forbidden => const CompletionForbidden(),
    _ => null,
  };

  /// Una sola uscita: coda e risposta possono chiudere il wizard insieme.
  void _leave(CompletionExit? exit) {
    if (_hasLeft) return;
    _hasLeft = true;
    Navigator.of(context).pop(exit);
  }

  static void _showSnackBar(BuildContext context, String message) =>
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

  Widget _buildScaffold(BuildContext context, MissionDraftState state) {
    return Theme(
      data: KlimmeckGuideTheme.compactButtonsOf(Theme.of(context)),
      child: Scaffold(
        // lo spazio della tastiera lo cede il corpo qui sotto: così le pagine
        // sanno che si sta scrivendo e tolgono contatore e pulsanti (UAT
        // 2026-11-14)
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text(MissionCompletionScreen.title),
          actions: [
            if (state is MissionDraftReady)
              TextButton(
                key: MissionCompletionScreen.discardKey,
                onPressed: state.isSubmitting ? null : _confirmDiscard,
                child: const Text(MissionCompletionScreen.discardLabel),
              ),
          ],
        ),
        body: DecoratedBox(
          decoration: KlimmeckGuideTheme.getParchmentBackground(),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: _keyboardInsetOf(context)),
              child: _buildBody(context, state),
            ),
          ),
        ),
      ),
    );
  }

  /// «Scontri» in orizzontale non ha altezza da cedere: la ricerca sta in
  /// cima e la tastiera copre il fondo della lista.
  double _keyboardInsetOf(BuildContext context) =>
      _page == MissionPage.encounters
      ? 0
      : MediaQuery.viewInsetsOf(context).bottom;

  Widget _buildBody(BuildContext context, MissionDraftState state) {
    return switch (state) {
      MissionDraftReady() => _buildReady(state),
      MissionDraftAbsent(:final isStarting) => StartStep(
        isStarting: isStarting,
        onStart: context.read<MissionDraftCubit>().start,
      ),
      MissionDraftLoadFailed(:final failure) => _LoadFailed(
        message: MissionCompletionScreen.failureLineOf(failure),
      ),
      MissionDraftLoading() ||
      MissionDraftCompleted() ||
      MissionDraftDiscarded() => const Center(child: KGLoader()),
    };
  }

  Widget _buildReady(MissionDraftReady ready) {
    final theme = KlimmeckGuideTheme.instance;
    // la tastiera in orizzontale lascia poche righe: il contatore cede il
    // posto al campo che si sta scrivendo, tranne su «Scontri» dove ospita la
    // ricerca (UAT 2026-11-14)
    final isTypingBelow =
        _page != MissionPage.encounters &&
        MediaQuery.viewInsetsOf(context).bottom > 0;
    return Padding(
      padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isTypingBelow) ...[
            Row(
              children: [
                MissionStepHeader(
                  stepNumber: _page.index + 1,
                  title: _titleOf(ready.draft),
                ),
                const SizedBox(width: KlimmeckGuideTheme.spacingMd),
                Expanded(child: _buildHeaderSide(theme)),
              ],
            ),
            const SizedBox(height: KlimmeckGuideTheme.spacingSm),
          ],
          Expanded(
            child: MissionBackScope(
              onBack: _page != MissionPage.place && !ready.isSubmitting
                  ? () => _goBack(ready.draft)
                  : null,
              child: _buildPage(ready),
            ),
          ),
        ],
      ),
    );
  }

  String _titleOf(MissionDraft draft) => switch (_page) {
    MissionPage.place => MissionCompletionScreen.placeTitle,
    MissionPage.encounters => MissionCompletionScreen.encountersTitle,
    MissionPage.fight => MissionCompletionScreen.fightTitle(
      _fightIndex,
      draft.fights.length,
    ),
    MissionPage.prizes => MissionCompletionScreen.prizesTitle,
    MissionPage.recap => MissionCompletionScreen.recapTitle,
  };

  Widget _buildPage(MissionDraftReady ready) => switch (_page) {
    MissionPage.place => _buildPlace(ready),
    MissionPage.encounters => EncountersStep(
      draft: ready.draft,
      isSubmitting: ready.isSubmitting,
      onNext: _saveFights,
    ),
    MissionPage.fight => FightStep(
      key: ValueKey(_fightIndex),
      draft: ready.draft,
      fightIndex: _fightIndex,
      isSubmitting: ready.isSubmitting,
      onSimulate: () => context.read<MissionDraftCubit>().simulate(_fightIndex),
      onChangeEnemies: () => setState(() => _enter(MissionPage.encounters)),
      onNext: (corrections) => _saveCorrections(ready.draft, corrections),
    ),
    MissionPage.prizes => PrizesStep(
      draft: ready.draft,
      isSubmitting: ready.isSubmitting,
      onNext: _savePrizes,
    ),
    MissionPage.recap => RecapStep(
      card: widget.card,
      draft: ready.draft,
      isSubmitting: ready.isSubmitting,
      onComplete: context.read<MissionDraftCubit>().complete,
    ),
  };

  Widget _buildPlace(MissionDraftReady ready) {
    return BlocBuilder<MissionParticipantsCubit, MissionParticipantsState>(
      builder: (context, participants) => PlaceStep(
        draft: ready.draft,
        participants: participants,
        isSubmitting: ready.isSubmitting,
        onTeleport: () => _teleportGroup(ready.draft),
        onStay: _stayAt,
        onRetry: () => _loadParticipants(ready.draft),
      ),
    );
  }

  /// Il primo partecipante porta con sé gli altri; all'atterraggio la Locanda
  /// riapre questo wizard dalla carta (D-01, D-28, Pitfall 1).
  void _teleportGroup(MissionDraft draft) {
    if (draft.participants case [final first, ...final rest]) {
      _prepareTeleport(first, rest);
    }
  }

  void _prepareTeleport(
    MissionParticipant first,
    List<MissionParticipant> rest,
  ) {
    context.read<TeleportModeCubit>().prepare(
      characterId: first.characterId,
      name: first.name,
      companionIds: [for (final participant in rest) participant.characterId],
      resumeCardKey: widget.card.cardKey,
    );
  }

  void _stayAt(String placeId) {
    final cubit = context.read<MissionDraftCubit>();
    _runThenOpen(
      () => cubit.saveStep(MissionDraftStep.fights, placeId: placeId),
      MissionPage.encounters,
    );
  }

  /// Zero scontri: storia narrativa, si passa ai premi (D-24). Con scontri il
  /// passo salvato torna `fights`: una ripresa non salta scontri da simulare.
  void _saveFights(List<List<MissionEnemyInput>> enemiesPerFight) {
    final cubit = context.read<MissionDraftCubit>();
    final hasFights = enemiesPerFight.isNotEmpty;
    _runThenOpen(
      () => cubit.saveFights(
        enemiesPerFight,
        step: hasFights ? MissionDraftStep.fights : MissionDraftStep.prizes,
      ),
      hasFights ? MissionPage.fight : MissionPage.prizes,
    );
  }

  /// Dopo l'ultimo scontro si passa ai premi (D-06).
  void _saveCorrections(
    MissionDraft draft,
    List<MissionCorrection> corrections,
  ) {
    final cubit = context.read<MissionDraftCubit>();
    final fightIndex = _fightIndex;
    final isLast = fightIndex == draft.fights.length - 1;
    _runThenOpen(
      () => cubit.saveCorrections(
        fightIndex,
        corrections,
        step: isLast ? MissionDraftStep.prizes : null,
      ),
      isLast ? MissionPage.prizes : MissionPage.fight,
      fightIndex: fightIndex + 1,
    );
  }

  void _savePrizes(List<MissionPrizeInput> prizes) {
    final cubit = context.read<MissionDraftCubit>();
    _runThenOpen(
      () => cubit.savePrizes(prizes, step: MissionDraftStep.recap),
      MissionPage.recap,
    );
  }

  /// T-21-46: la pagina cambia solo se la chiamata non è stata rifiutata.
  Future<void> _runThenOpen(
    Future<void> Function() action,
    MissionPage next, {
    int fightIndex = 0,
  }) async {
    final cubit = context.read<MissionDraftCubit>();
    final serial = _failureSerialOf(cubit.state);
    await action();
    if (!mounted) return;
    final state = cubit.state;
    if (state is! MissionDraftReady || state.failureSerial != serial) return;
    setState(() => _enter(next, fightIndex: fightIndex));
  }

  /// Accanto al contatore dei passi: la ricerca dei nemici su «Scontri», la
  /// nota della bozza su «Luogo», nulla sulle pagine fitte (UAT 2026-11-14).
  Widget _buildHeaderSide(KlimmeckGuideTheme theme) => switch (_page) {
    MissionPage.encounters => const EnemySearchBar(),
    MissionPage.place => Text(
      MissionCompletionScreen.leaveNote,
      style: theme.bodyMedium,
    ),
    _ => const SizedBox.shrink(),
  };

  void _goBack(MissionDraft draft) =>
      setState(() => _enterPrevious(draft.fights.length));

  /// Gli scontri si ripercorrono uno per uno: «Premi» torna all'ultimo,
  /// il primo torna a «Scontri».
  void _enterPrevious(int fightCount) => switch (_page) {
    MissionPage.fight when _fightIndex > 0 => _enter(
      MissionPage.fight,
      fightIndex: _fightIndex - 1,
    ),
    MissionPage.prizes when fightCount > 0 => _enter(
      MissionPage.fight,
      fightIndex: fightCount - 1,
    ),
    MissionPage.prizes || MissionPage.fight => _enter(MissionPage.encounters),
    MissionPage.recap => _enter(MissionPage.prizes),
    MissionPage.encounters || MissionPage.place => _enter(MissionPage.place),
  };

  /// D-11: scartare libera i partecipanti; il teletrasporto fatto resta.
  Future<void> _confirmDiscard() async {
    final confirmed = await showDestructiveConfirmation(
      context,
      title: MissionCompletionScreen.discardTitle,
      body: MissionCompletionScreen.discardBody,
      confirmLabel: MissionCompletionScreen.discardLabel,
    );
    if (!confirmed || !mounted) return;
    await context.read<MissionDraftCubit>().discard();
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: KlimmeckGuideTheme.instance.bodyMedium),
          const SizedBox(height: KlimmeckGuideTheme.spacingSm),
          ElevatedButton(
            key: MissionCompletionScreen.retryKey,
            style: KlimmeckGuideTheme.primaryButtonStyle,
            onPressed: () => context.read<MissionDraftCubit>().load(),
            child: const Text(MissionCompletionScreen.retryLabel),
          ),
        ],
      ),
    );
  }
}
