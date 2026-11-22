import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/config/story_and_wound_corrections.dart';
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
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/participant_story.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/additions_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/encounters_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/fight_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/place_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/prizes_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/recap_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/stories_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/shared/components/modal/destructive_confirmation_dialog.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Pagine del wizard: navigazione locale, mai salvata (la bozza servita tiene
/// il passo, D-09). `stories` è la pagina di lettura: la prima, mai un passo
/// salvato. `additions` è l'ultima, raggiungibile solo con le aggiunte alle
/// storie accese (Phase 24 D-04).
enum MissionPage { stories, place, encounters, fight, prizes, recap, additions }

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
    this.isStoryAndWoundInputEnabled = storyAndWoundCorrectionsEnabled,
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
  static const String storiesTitle = 'Storie';
  static const String placeTitle = 'Luogo';
  static const String encountersTitle = 'Scontri';
  static const String prizesTitle = 'Premi';
  static const String recapTitle = 'Riepilogo';
  static const String additionsTitle = 'Aggiunte alle storie';
  static String fightTitle(int index, int count) =>
      'Scontro ${index + 1} di $count';
  static const String invalidValuesMessage =
      'Operazione rifiutata: controlla scontri, correzioni e premi';
  static const String notParticipantMessage =
      'Un partecipante non fa più parte della richiesta';
  static const String additionTooLongMessage =
      "Un'aggiunta supera i 1000 caratteri";
  static const String connectionMessage = 'Connessione assente, riprova';
  static const String genericMessage = 'Qualcosa è andato storto, riprova';
  static const Key startKey = ValueKey('mission.start');
  static const Key discardKey = ValueKey('mission.discard');
  static const Key backKey = MissionBackButton.buttonKey;
  static const Key nextKey = ValueKey('mission.next');
  static const Key retryKey = ValueKey('mission.retry');

  /// Riga della conferma per un'aggiunta scritta (Phase 24 D-05).
  static String storyPageLineOf(String name) =>
      'Storia di $name: una nuova pagina';

  /// Riga d'errore del wizard per un rifiuto o una lettura fallita.
  static String failureLineOf(InnkeeperFailure failure) => switch (failure) {
    InnkeeperFailure.overrideInvalid => invalidValuesMessage,
    InnkeeperFailure.notParticipant => notParticipantMessage,
    InnkeeperFailure.additionTooLong => additionTooLongMessage,
    InnkeeperFailure.connection => connectionMessage,
    _ => genericMessage,
  };

  final RequestCard card;

  /// Dopo un teletrasporto annullato l'oste torna a «Luogo», da dove era
  /// partito, qualunque sia il passo servito (UAT 2026-11-14).
  final bool opensAtPlace;

  /// Spento, il flusso finisce sul riepilogo e nulla di nuovo parte verso il
  /// BE; acceso, si chiude sull'ultima pagina con le aggiunte (Phase 24 D-04).
  final bool isStoryAndWoundInputEnabled;

  @override
  State<MissionCompletionScreen> createState() =>
      _MissionCompletionScreenState();
}

class _MissionCompletionScreenState extends State<MissionCompletionScreen> {
  MissionPage _page = MissionPage.stories;
  int _fightIndex = 0;
  bool _hasLeft = false;

  /// Aggiunte scritte finora, per id del personaggio; `null` finché l'ultima
  /// pagina non è mai stata aperta.
  Map<String, String>? _seededAdditions;

  Map<String, String> get _additionTexts => _seededAdditions ?? const {};

  /// L'oste non resta mai chiuso nel wizard senza rete: dopo un salvataggio
  /// d'uscita rifiutato il tentativo successivo esce senza salvare, finché
  /// non scrive ancora.
  bool _wasLeaveSaveRefused = false;

  /// L'ultima pagina esiste solo con le aggiunte accese.
  List<MissionPage> get _reachablePages => [
    for (final page in MissionPage.values)
      if (page != MissionPage.additions || widget.isStoryAndWoundInputEnabled)
        page,
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<MissionDraftCubit>().state;
    if (state is MissionDraftReady) _openServedStep(state.draft);
    if (state is MissionDraftAbsent) _readCardStories();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PendingRequestsCubit, PendingRequestsState>(
          listenWhen: (_, current) => _isRequestGone(current),
          listener: (context, _) => _leaveGoneUnlessCalling(context),
        ),
        // il completamento toglie la richiesta dalla coda prima che arrivi la
        // sua risposta: a chiamata finita si ricontrolla (UAT 2026-11-14)
        BlocListener<MissionDraftCubit, MissionDraftState>(
          listenWhen: (previous, current) =>
              _isCallInFlight(previous) && !_isCallInFlight(current),
          listener: (context, _) => _leaveGoneUnlessCalling(context),
        ),
        BlocListener<MissionDraftCubit, MissionDraftState>(
          listenWhen: _isDraftServed,
          listener: (_, state) => setState(
            () => _openServedStep((state as MissionDraftReady).draft),
          ),
        ),
        BlocListener<MissionDraftCubit, MissionDraftState>(
          listenWhen: _isDraftStarted,
          listener: (_, state) => setState(
            () => _openStartedStep((state as MissionDraftReady).draft),
          ),
        ),
        BlocListener<MissionDraftCubit, MissionDraftState>(
          listenWhen: (previous, current) =>
              previous is! MissionDraftAbsent && current is MissionDraftAbsent,
          listener: (_, _) => _readCardStories(),
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
          canPop: !_isCallInFlight(state) && !_mustSaveBeforeLeaving(state),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _saveAdditionsThenLeave();
          },
          child: _buildScaffold(context, state),
        ),
      ),
    );
  }

  /// Una chiamata in corso decide lei l'uscita: i risultati del completamento,
  /// o `NOT_FOUND` se la richiesta è sparita davvero.
  void _leaveGoneUnlessCalling(BuildContext context) {
    final draft = context.read<MissionDraftCubit>().state;
    if (_isCallInFlight(draft)) return;
    if (draft is MissionDraftCompleted || draft is MissionDraftDiscarded) {
      return;
    }
    if (!_isRequestGone(context.read<PendingRequestsCubit>().state)) return;
    _leave(const CompletionGone());
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
    _openStepOf(draft);
    context.read<MissionParticipantsCubit>().ensureLoaded(
      _characterIdsOf(draft),
    );
  }

  /// Le storie sono state lette a partecipanti liberi (D-02): ora che l'avvio
  /// li ha bloccati «Luogo» chiede posizioni nuove. Le storie restano in
  /// mostra e nessun loader ferma il wizard.
  void _openStartedStep(MissionDraft draft) {
    _openStepOf(draft);
    context.read<MissionParticipantsCubit>().reread(_characterIdsOf(draft));
  }

  void _openStepOf(MissionDraft draft) {
    final page = widget.opensAtPlace ? MissionPage.place : _pageOf(draft.step);
    _enter(page);
    if (_showsPrizeNamesFrom(page)) _loadPrizeNames(_characterIdsOf(draft));
  }

  /// Una bozza appena creata da «Inizia la missione».
  static bool _isDraftStarted(
    MissionDraftState previous,
    MissionDraftState current,
  ) => previous is MissionDraftAbsent && current is MissionDraftReady;

  /// Una bozza che esisteva già: letta all'apertura o dopo un «Riprova».
  static bool _isDraftServed(
    MissionDraftState previous,
    MissionDraftState current,
  ) =>
      previous is! MissionDraftReady &&
      previous is! MissionDraftAbsent &&
      current is MissionDraftReady;

  /// Dall'ultima pagina «Indietro» porta al riepilogo.
  static bool _showsPrizeNamesFrom(MissionPage page) =>
      page == MissionPage.recap || page == MissionPage.additions;

  /// Senza bozza le storie si leggono con i partecipanti della scheda: la
  /// missione non è iniziata e nessuno è bloccato (D-02).
  void _readCardStories() =>
      context.read<MissionParticipantsCubit>().ensureLoaded(_cardCharacterIds);

  List<String> get _cardCharacterIds => [
    for (final participant in widget.card.participants) participant.id,
  ];

  /// «Riprova»: rilegge anche ciò che era già stato letto.
  void _reloadParticipants(List<String> characterIds) =>
      context.read<MissionParticipantsCubit>().load(characterIds);

  static List<String> _characterIdsOf(MissionDraft draft) => [
    for (final participant in draft.participants) participant.characterId,
  ];

  /// «Premi» legge le opzioni da sé; un «Riepilogo» riaperto le chiede qui
  /// per dare un nome ai premi scelti (D-22).
  void _loadPrizeNames(List<String> characterIds) =>
      context.read<MissionPrizeOptionsCubit>().loadAll(characterIds);

  /// Unico punto in cui la pagina cambia: «Scontri» chiede la lista dei
  /// nemici solo se non c'è ancora (D-03), l'ultima pagina prende i suoi
  /// testi dalla bozza.
  void _enter(MissionPage page, {int fightIndex = 0}) {
    _page = page;
    _fightIndex = fightIndex;
    if (page == MissionPage.encounters) _loadEnemiesIfMissing();
    if (page == MissionPage.additions) _seedAdditionsOnce();
  }

  /// Una volta sola: una bozza servita dopo non riscrive ciò che l'oste sta
  /// scrivendo (Phase 24 D-05).
  void _seedAdditionsOnce() {
    final state = context.read<MissionDraftCubit>().state;
    if (_seededAdditions != null || state is! MissionDraftReady) return;
    _seededAdditions = {
      for (final addition in state.draft.backgroundAdditions)
        addition.characterId: addition.text,
    };
  }

  void _loadEnemiesIfMissing() {
    final enemies = context.read<MissionEnemiesCubit>();
    if (enemies.state.enemies.isNotEmpty || enemies.state.isLoading) return;
    enemies.load();
  }

  MissionPage _pageOf(MissionDraftStep? step) => switch (step) {
    MissionDraftStep.fights => MissionPage.encounters,
    MissionDraftStep.prizes => MissionPage.prizes,
    MissionDraftStep.recap => MissionPage.recap,
    // trappola dei nomi: il passo `stories` del BE è l'ULTIMA pagina (le
    // aggiunte), non la pagina di lettura [MissionPage.stories]; con le
    // aggiunte spente l'ultima pagina raggiungibile è il riepilogo
    MissionDraftStep.stories => _reachablePages.last,
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

  /// Uscire dall'ultima pagina con testo non salvato lo salva prima (Phase 24
  /// D-05).
  bool _mustSaveBeforeLeaving(MissionDraftState state) =>
      _page == MissionPage.additions &&
      !_wasLeaveSaveRefused &&
      state is MissionDraftReady &&
      _hasUnsavedAdditions(state.draft);

  /// Il BE toglie gli spazi ai bordi: un testo che cambia solo lì è già
  /// salvato.
  bool _hasUnsavedAdditions(MissionDraft draft) => draft.participants.any(
    (participant) =>
        _writtenAdditionOf(participant.characterId) !=
        (draft.additionOf(participant.characterId)?.text ?? ''),
  );

  /// Un'uscita fermata da una chiamata in corso resta ferma: nulla da fare.
  Future<void> _saveAdditionsThenLeave() async {
    final cubit = context.read<MissionDraftCubit>();
    if (!_mustSaveBeforeLeaving(cubit.state)) return;
    if (_isCallInFlight(cubit.state)) return;
    final isSaved = await _isAccepted(
      () => cubit.saveAdditions(_additionTexts),
    );
    if (!mounted) return;
    if (isSaved) return _leave(null);
    setState(() => _wasLeaveSaveRefused = true);
  }

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
      MissionDraftAbsent(:final isStarting) => _buildFrame(
        stepNumber: MissionPage.stories.index + 1,
        title: MissionCompletionScreen.storiesTitle,
        headerSide: const SizedBox.shrink(),
        onBack: null,
        page: _buildStories(
          readersOf: _cardReaders,
          onRetry: () => _reloadParticipants(_cardCharacterIds),
          footer: StoriesStartFooter(
            isStarting: isStarting,
            onStart: context.read<MissionDraftCubit>().start,
          ),
        ),
      ),
      MissionDraftLoadFailed(:final failure) => _LoadFailed(
        message: MissionCompletionScreen.failureLineOf(failure),
      ),
      MissionDraftLoading() ||
      MissionDraftCompleted() ||
      MissionDraftDiscarded() => const Center(child: KGLoader()),
    };
  }

  Widget _buildReady(MissionDraftReady ready) => _buildFrame(
    stepNumber: _page.index + 1,
    title: _titleOf(ready.draft),
    headerSide: _buildHeaderSide(KlimmeckGuideTheme.instance),
    onBack: _page != MissionPage.stories && !ready.isSubmitting
        ? () => _goBack(ready.draft)
        : null,
    page: _buildPage(ready),
  );

  /// Contatore dei passi sopra, pagina sotto: la stessa cornice con e senza
  /// bozza.
  Widget _buildFrame({
    required int stepNumber,
    required String title,
    required Widget headerSide,
    required VoidCallback? onBack,
    required Widget page,
  }) {
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
                  stepNumber: stepNumber,
                  stepCount: _reachablePages.length,
                  title: title,
                ),
                const SizedBox(width: KlimmeckGuideTheme.spacingMd),
                Expanded(child: headerSide),
              ],
            ),
            const SizedBox(height: KlimmeckGuideTheme.spacingSm),
          ],
          Expanded(
            child: MissionBackScope(onBack: onBack, child: page),
          ),
        ],
      ),
    );
  }

  Widget _buildStories({
    required List<StoryReader> Function(MissionParticipantsState) readersOf,
    required VoidCallback onRetry,
    required Widget footer,
  }) {
    return BlocBuilder<MissionParticipantsCubit, MissionParticipantsState>(
      builder: (context, participants) => StoriesStep(
        readers: readersOf(participants),
        participants: participants,
        onRetry: onRetry,
        footer: footer,
      ),
    );
  }

  /// Prima della bozza il rango arriva dal personaggio letto: `null` finché
  /// la lettura non finisce (D-03).
  List<StoryReader> _cardReaders(MissionParticipantsState participants) {
    final loaded = switch (participants) {
      final MissionParticipantsLoaded loaded => loaded,
      _ => null,
    };
    return [
      for (final participant in widget.card.participants)
        StoryReader(
          characterId: participant.id,
          name: participant.name,
          title: loaded?.titleOf(participant.id),
        ),
    ];
  }

  static List<StoryReader> _draftReaders(MissionDraft draft) =>
      draft.participants.map(StoryReader.ofParticipant).toList();

  String _titleOf(MissionDraft draft) => switch (_page) {
    MissionPage.stories => MissionCompletionScreen.storiesTitle,
    MissionPage.place => MissionCompletionScreen.placeTitle,
    MissionPage.encounters => MissionCompletionScreen.encountersTitle,
    MissionPage.fight => MissionCompletionScreen.fightTitle(
      _fightIndex,
      draft.fights.length,
    ),
    MissionPage.prizes => MissionCompletionScreen.prizesTitle,
    MissionPage.recap => MissionCompletionScreen.recapTitle,
    MissionPage.additions => MissionCompletionScreen.additionsTitle,
  };

  Widget _buildPage(MissionDraftReady ready) => switch (_page) {
    MissionPage.stories => _buildStories(
      readersOf: (_) => _draftReaders(ready.draft),
      onRetry: () => _reloadParticipants(_characterIdsOf(ready.draft)),
      // locale: sulla bozza non è cambiato nulla, niente da salvare (D-02)
      footer: StoriesNextFooter(
        onNext: () => setState(() => _enter(MissionPage.place)),
      ),
    ),
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
      isWoundRemovalEnabled: widget.isStoryAndWoundInputEnabled,
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
      onNext: widget.isStoryAndWoundInputEnabled ? _openAdditions : null,
    ),
    MissionPage.additions => _buildAdditions(ready),
  };

  Widget _buildAdditions(MissionDraftReady ready) {
    return BlocBuilder<MissionParticipantsCubit, MissionParticipantsState>(
      builder: (context, participants) => AdditionsStep(
        readers: _draftReaders(ready.draft),
        participants: participants,
        texts: _additionTexts,
        onChanged: _writeAddition,
        isSubmitting: ready.isSubmitting,
        onConclude: () => _confirmConclusion(ready.draft),
        onRetry: () => _reloadParticipants(_characterIdsOf(ready.draft)),
      ),
    );
  }

  void _writeAddition(String characterId, String text) => setState(() {
    _seededAdditions = {..._additionTexts, characterId: text};
    _wasLeaveSaveRefused = false;
  });

  /// L'unico completamento con le aggiunte accese: conferma, poi salvataggio
  /// e completamento in una sola azione del Cubit (Phase 24 D-05).
  Future<void> _confirmConclusion(MissionDraft draft) async {
    final confirmed = await confirmMissionCompletion(
      context,
      lines: _conclusionLinesOf(draft),
    );
    if (!confirmed || !mounted) return;
    await context.read<MissionDraftCubit>().conclude(_additionTexts);
  }

  List<String> _conclusionLinesOf(MissionDraft draft) => [
    ...missionRecapLinesOf(questTitle: widget.card.questTitle, draft: draft),
    for (final participant in draft.participants)
      if (_writtenAdditionOf(participant.characterId).isNotEmpty)
        MissionCompletionScreen.storyPageLineOf(participant.name),
  ];

  String _writtenAdditionOf(String characterId) =>
      (_additionTexts[characterId] ?? '').trim();

  Widget _buildPlace(MissionDraftReady ready) {
    return BlocBuilder<MissionParticipantsCubit, MissionParticipantsState>(
      builder: (context, participants) => PlaceStep(
        draft: ready.draft,
        participants: participants,
        isSubmitting: ready.isSubmitting,
        onTeleport: () => _teleportGroup(ready.draft),
        onStay: _stayAt,
        onRetry: () => _reloadParticipants(_characterIdsOf(ready.draft)),
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
        declaresRemovals: widget.isStoryAndWoundInputEnabled,
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

  /// Il passo `stories` del BE segna l'ultima pagina (Phase 24 D-05).
  void _openAdditions() {
    final cubit = context.read<MissionDraftCubit>();
    _runThenOpen(
      () => cubit.saveStep(MissionDraftStep.stories),
      MissionPage.additions,
    );
  }

  /// T-21-46: la pagina cambia solo se la chiamata non è stata rifiutata.
  Future<void> _runThenOpen(
    Future<void> Function() action,
    MissionPage next, {
    int fightIndex = 0,
  }) async {
    if (!await _isAccepted(action)) return;
    setState(() => _enter(next, fightIndex: fightIndex));
  }

  /// Vero se la schermata è ancora qui e la chiamata non è stata rifiutata.
  Future<bool> _isAccepted(Future<void> Function() action) async {
    final cubit = context.read<MissionDraftCubit>();
    final serial = _failureSerialOf(cubit.state);
    await action();
    if (!mounted) return false;
    final state = cubit.state;
    return state is MissionDraftReady && state.failureSerial == serial;
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

  void _goBack(MissionDraft draft) {
    if (_page == MissionPage.additions && _hasUnsavedAdditions(draft)) {
      return _saveAdditionsThenOpenRecap();
    }
    setState(() => _enterPrevious(draft.fights.length));
  }

  /// Phase 24 D-05: tornando al riepilogo le aggiunte scritte restano nella
  /// bozza.
  void _saveAdditionsThenOpenRecap() {
    final cubit = context.read<MissionDraftCubit>();
    _runThenOpen(() => cubit.saveAdditions(_additionTexts), MissionPage.recap);
  }

  /// Gli scontri si ripercorrono uno per uno: «Premi» torna all'ultimo,
  /// il primo torna a «Scontri»; da «Luogo» si rileggono le storie (D-02).
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
    MissionPage.additions => _enter(MissionPage.recap),
    MissionPage.recap => _enter(MissionPage.prizes),
    MissionPage.encounters => _enter(MissionPage.place),
    MissionPage.place || MissionPage.stories => _enter(MissionPage.stories),
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
