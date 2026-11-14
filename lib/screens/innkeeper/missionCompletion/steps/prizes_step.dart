import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_limits.dart';
import 'package:klimmeck_guide/models/mission/mission_prize.dart';
import 'package:klimmeck_guide/models/mission/mission_prize_options.dart';
import 'package:klimmeck_guide/models/quantity_line.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/mission_back_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/completion_recap.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/quantity_stepper.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/prize_catalogue_sheet.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

/// Passo «Premi» (D-07, D-15, D-22): parte dai premi che il BE ha
/// precompilato nella bozza; monete e PE sono numeri liberi, oggetti,
/// compagno e magia arrivano solo dal catalogo servito. Il BE rivalida tutto.
class PrizesStep extends StatefulWidget {
  const PrizesStep({
    super.key,
    required this.draft,
    required this.isSubmitting,
    required this.onNext,
  });

  static const String addPrizeLabel = 'Aggiungi premio';
  static const String addCureLabel = 'Aggiungi cura';
  static const String coinsHeading = 'Monete';
  static const String xpLabel = 'PE';
  static const String removeTooltip = 'Rimuovi';
  static Key headerKeyFor(String characterId) =>
      ValueKey('mission.prizes.header.$characterId');
  static Key addPrizeKeyFor(String characterId) =>
      ValueKey('mission.prizes.add.$characterId');
  static Key retryKeyFor(String characterId) =>
      ValueKey('mission.prizes.retry.$characterId');
  static Key addCureKeyFor(String characterId) =>
      ValueKey('mission.prizes.addCure.$characterId');

  /// `coin` = `gold` | `silver` | `copper`.
  static Key coinFieldKeyFor(String characterId, String coin) =>
      ValueKey('mission.prizes.coins.$coin.$characterId');
  static Key xpFieldKeyFor(String characterId) =>
      ValueKey('mission.prizes.xp.$characterId');

  final MissionDraft draft;
  final bool isSubmitting;

  /// Premi nell'ordine dei partecipanti.
  final void Function(List<MissionPrizeInput> prizes) onNext;

  @override
  State<PrizesStep> createState() => _PrizesStepState();
}

enum _Coin {
  gold(CloudinaryAssets.goldCoin),
  silver(CloudinaryAssets.silverCoin),
  copper(CloudinaryAssets.copperCoin);

  const _Coin(this.assetId);

  final String assetId;
}

class _PrizesStepState extends State<PrizesStep> {
  /// Personaggi con la tendina aperta: sopravvive allo scorrimento della lista.
  final Set<String> _openTiles = {};

  static const double _entrySize = 48;
  static const double _coinIconSize = 20;
  static const double _loaderHeight = 32;
  static const double _stepperWidth = 220;
  static const String _cureFallback = 'Cura';

  late Map<String, MissionPrizeInput> _prizes;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _prizes = {
      for (final participant in widget.draft.participants)
        participant.characterId: _servedPrizeOf(participant.characterId),
    };
    for (final MapEntry(key: id, value: prize) in _prizes.entries) {
      _controllers[_coinKey(id, _Coin.gold)] = _controllerOf(prize.coins.gold);
      _controllers[_coinKey(id, _Coin.silver)] = _controllerOf(
        prize.coins.silver,
      );
      _controllers[_coinKey(id, _Coin.copper)] = _controllerOf(
        prize.coins.copper,
      );
      _controllers[_xpKey(id)] = _controllerOf(prize.xp);
    }
    context.read<MissionPrizeOptionsCubit>().loadAll(_prizes.keys.toList());
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// D-22: un partecipante senza premio servito parte vuoto, mai dal blocco.
  MissionPrizeInput _servedPrizeOf(String characterId) {
    final served = widget.draft.prizeOf(characterId);
    if (served != null) return MissionPrizeInput.of(served);
    return MissionPrizeInput(
      characterId: characterId,
      coins: const Coins(),
      xp: 0,
      cure: false,
    );
  }

  static TextEditingController _controllerOf(int value) =>
      TextEditingController(text: '$value');

  static String _coinKey(String characterId, _Coin coin) =>
      '$characterId.${coin.name}';

  static String _xpKey(String characterId) => '$characterId.xp';

  static int _amountOf(String text) => int.tryParse(text) ?? 0;

  void _update(
    String characterId,
    MissionPrizeInput Function(MissionPrizeInput) change,
  ) => setState(() => _prizes[characterId] = change(_prizes[characterId]!));

  void _setCoin(String characterId, _Coin coin, String text) =>
      _update(characterId, (prize) {
        final amount = _amountOf(text);
        final coins = prize.coins;
        return prize.withCoins(
          Coins(
            gold: coin == _Coin.gold ? amount : coins.gold,
            silver: coin == _Coin.silver ? amount : coins.silver,
            copper: coin == _Coin.copper ? amount : coins.copper,
          ),
        );
      });

  void _goOn() => widget.onNext([
    for (final participant in widget.draft.participants)
      _prizes[participant.characterId]!,
  ]);

  Future<void> _openCatalogue(
    String characterId,
    MissionPrizeOptions options,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PrizeCatalogueSheet(
      options: options,
      onPickItem: (item) =>
          _update(characterId, (prize) => prize.withItemAdded(item.id)),
      onPickPet: (pet) =>
          _update(characterId, (prize) => prize.withPet(pet.id)),
      onPickSpell: (spell) =>
          _update(characterId, (prize) => prize.withSpell(spell.id)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MissionPrizeOptionsCubit, MissionPrizeOptionsState>(
      builder: (context, options) {
        final participants = widget.draft.participants;
        // con la tastiera aperta in orizzontale resta spazio solo per il campo
        // che si sta scrivendo: la riga dei pulsanti torna alla chiusura (UAT
        // 2026-11-14)
        final isTyping = MediaQuery.viewInsetsOf(context).bottom > 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: participants.length,
                itemBuilder: (_, index) =>
                    _participantTile(participants[index], options),
              ),
            ),
            if (!isTyping)
              Row(
                children: [
                  const MissionBackButton(),
                  const Spacer(),
                  ElevatedButton(
                    key: MissionCompletionScreen.nextKey,
                    style: KlimmeckGuideTheme.primaryButtonStyle,
                    onPressed:
                        widget.isSubmitting || !widget.draft.allFightsSimulated
                        ? null
                        : _goOn,
                    child: const Text(MissionCompletionScreen.nextLabel),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  /// I premi di un personaggio stanno sotto il suo nome, chiusi finché l'oste
  /// non li apre (UAT 2026-11-14).
  Widget _participantTile(
    MissionParticipant participant,
    MissionPrizeOptionsState state,
  ) {
    final id = participant.characterId;
    return ExpansionTile(
      // mai una PageStorageKey: i campi di testo qui sotto leggerebbero lo
      // stesso posto e si romperebbero; l'apertura la ricorda la pagina
      key: ValueKey('mission.prizes.tile.$id'),
      initiallyExpanded: _openTiles.contains(id),
      onExpansionChanged: (isOpen) =>
          isOpen ? _openTiles.add(id) : _openTiles.remove(id),
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      title: _header(participant, state.options[id]),
      children: [for (final row in _rowsOf(participant, state)) row()],
    );
  }

  List<Widget Function()> _rowsOf(
    MissionParticipant participant,
    MissionPrizeOptionsState state,
  ) {
    final id = participant.characterId;
    final prize = _prizes[id]!;
    final options = state.options[id];
    final isLoading = options == null && state.loading.contains(id);
    final failure = options == null ? state.failures[id] : null;
    return [
      if (failure != null) () => _failureRow(id, failure),
      () => _coinsRow(id),
      () => _xpField(id),
      if (prize.cure)
        () => _cureRow(id, options)
      else if (options?.blockCure != null)
        () => _addCureRow(id),
      if (isLoading)
        () => const KGLoader(height: _loaderHeight)
      else ...[
        for (final item in prize.items) () => _itemRow(id, item, options),
        if (prize.petId case final petId?) () => _petRow(id, petId, options),
        if (prize.spellId case final spellId?)
          () => _spellRow(id, spellId, options),
      ],
    ];
  }

  Widget _header(MissionParticipant participant, MissionPrizeOptions? options) {
    final theme = KlimmeckGuideTheme.instance;
    final title = participant.title?.label;
    final canAdd = options != null && !widget.isSubmitting;
    return Row(
      children: [
        Expanded(
          child: Text(
            title == null ? participant.name : '${participant.name} · $title',
            key: PrizesStep.headerKeyFor(participant.characterId),
            style: theme.titleMedium,
          ),
        ),
        TextButton(
          key: PrizesStep.addPrizeKeyFor(participant.characterId),
          onPressed: canAdd
              ? () => _openCatalogue(participant.characterId, options)
              : null,
          child: const Text(PrizesStep.addPrizeLabel),
        ),
      ],
    );
  }

  /// Opzioni non lette: errore e «Riprova», mai un «Aggiungi premio» spento
  /// senza motivo.
  Widget _failureRow(String characterId, InnkeeperFailure failure) {
    return Row(
      children: [
        Expanded(
          child: Text(
            MissionCompletionScreen.failureLineOf(failure),
            style: KlimmeckGuideTheme.instance.bodyMedium,
          ),
        ),
        TextButton(
          key: PrizesStep.retryKeyFor(characterId),
          onPressed: () =>
              context.read<MissionPrizeOptionsCubit>().loadFor(characterId),
          child: const Text(MissionCompletionScreen.retryLabel),
        ),
      ],
    );
  }

  Widget _coinsRow(String characterId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          PrizesStep.coinsHeading,
          style: KlimmeckGuideTheme.instance.bodyMedium,
        ),
        Row(
          children: [
            for (final coin in _Coin.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: KlimmeckGuideTheme.spacingSm,
                  ),
                  child: _numberField(
                    key: PrizesStep.coinFieldKeyFor(characterId, coin.name),
                    controller: _controllers[_coinKey(characterId, coin)]!,
                    prefixIcon: CachedSvg(
                      url: CloudinaryAssets.url(coin.assetId),
                      width: _coinIconSize,
                      height: _coinIconSize,
                    ),
                    onChanged: (text) => _setCoin(characterId, coin, text),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _xpField(String characterId) => _numberField(
    key: PrizesStep.xpFieldKeyFor(characterId),
    controller: _controllers[_xpKey(characterId)]!,
    labelText: PrizesStep.xpLabel,
    onChanged: (text) =>
        _update(characterId, (prize) => prize.withXp(_amountOf(text))),
  );

  /// D-15: interi non negativi senza tetto di prodotto; solo cifre e al più
  /// [maxPrizeAmountDigits], il tetto tecnico del BE. Il BE resta giudice.
  Widget _numberField({
    required Key key,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    Widget? prefixIcon,
    String? labelText,
  }) {
    return TextField(
      key: key,
      controller: controller,
      enabled: !widget.isSubmitting,
      keyboardType: TextInputType.number,
      maxLength: maxPrizeAmountDigits,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
        counterText: '',
      ),
      onChanged: onChanged,
    );
  }

  /// Il testo legge la cura del blocco: quella servita è `null` dopo una
  /// rimozione salvata (D-22).
  Widget _cureRow(String characterId, MissionPrizeOptions? options) {
    final cure = options?.blockCure ?? widget.draft.prizeOf(characterId)?.cure;
    return _removable(
      onRemove: () => _update(characterId, (prize) => prize.withoutCure()),
      child: Text(
        lifeShareLine(cure) ?? _cureFallback,
        style: KlimmeckGuideTheme.instance.bodyMedium,
      ),
    );
  }

  Widget _addCureRow(String characterId) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(
      key: PrizesStep.addCureKeyFor(characterId),
      onPressed: widget.isSubmitting
          ? null
          : () => _update(characterId, (prize) => prize.withCure()),
      child: const Text(PrizesStep.addCureLabel),
    ),
  );

  Widget _itemRow(
    String characterId,
    MissionPrizeItem item,
    MissionPrizeOptions? options,
  ) {
    final assetItem = options?.itemById(item.itemId);
    return _removable(
      onRemove: () =>
          _update(characterId, (prize) => prize.withoutItem(item.itemId)),
      child: Row(
        children: [
          Expanded(
            child: assetItem == null
                ? Text(
                    quantityLine(item.quantity, unnamedItemLabel),
                    style: KlimmeckGuideTheme.instance.bodyMedium,
                  )
                : ItemRow(
                    assetItem: assetItem,
                    showCoins: false,
                    size: _entrySize,
                  ),
          ),
          SizedBox(
            width: _stepperWidth,
            child: QuantityStepper(
              label: '',
              value: item.quantity,
              min: minPrizeItemQuantity,
              max: maxPrizeItemQuantity,
              onChanged: (quantity) => _update(
                characterId,
                (prize) => prize.withItemQuantity(item.itemId, quantity),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _petRow(
    String characterId,
    String petId,
    MissionPrizeOptions? options,
  ) {
    final pet = options?.petById(petId);
    return _removable(
      onRemove: () => _update(characterId, (prize) => prize.withPet(null)),
      child: pet == null
          ? Text(petId, style: KlimmeckGuideTheme.instance.bodyMedium)
          : CompanionRow(pet: pet, size: _entrySize, showCoins: false),
    );
  }

  Widget _spellRow(
    String characterId,
    String spellId,
    MissionPrizeOptions? options,
  ) {
    final spell = options?.spellById(spellId);
    final theme = KlimmeckGuideTheme.instance;
    return _removable(
      onRemove: () => _update(characterId, (prize) => prize.withSpell(null)),
      child: Row(
        children: [
          if (spell != null) SpellCard(spell: spell, size: _entrySize),
          const SizedBox(width: KlimmeckGuideTheme.spacingSm),
          Expanded(
            child: Text(
              spell?.name ?? unnamedSpellLabel,
              style: theme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _removable({required Widget child, required VoidCallback onRemove}) {
    return Row(
      children: [
        Expanded(child: child),
        IconButton(
          tooltip: PrizesStep.removeTooltip,
          icon: const Icon(Icons.close),
          onPressed: widget.isSubmitting ? null : onRemove,
        ),
      ],
    );
  }
}
