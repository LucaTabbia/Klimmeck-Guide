import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/loot_item_card.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/enemy_portrait.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/utils.dart';

import '../../../models/quest/quest.dart';
import '../../../models/quest/quest_sheet_details.dart';
import '../../../models/quest/quest_viewer.dart';
import '../../../models/travel/travel_preview.dart';
import '../cards/equipment_item_card.dart';

class QuestInfoSheet extends StatelessWidget {
  const QuestInfoSheet({
    super.key,
    required this.quest,
    this.viewer,
    this.stateLabel,
    this.onAbandon,
    this.travelPreview,
  });

  final Quest? quest;

  /// Chi guarda (board): abilita titolo evidenziato, motivo del blocco, saldo.
  /// Null = sola lettura (mappa).
  final QuestViewer? viewer;

  /// Etichetta di stato della corsia (mappa, D-15).
  final String? stateLabel;

  /// Solo dalla mappa, mentre la corsia aspetta il gruppo (BE 09-19).
  final VoidCallback? onAbandon;

  /// Anteprima del viaggio automatico (solo Bacheca, swipe disponibile, D-04).
  /// Null = nessuna riga «Viaggio» (mappa, in attesa, fallita, nessun viaggio).
  final TravelPreview? travelPreview;

  static const Key combatFamilyKey = ValueKey('questSheet.family.combat');
  static const Key narrativeFamilyKey = ValueKey('questSheet.family.narrative');
  static const Key serviceFamilyKey = ValueKey('questSheet.family.service');
  static const Key costLineKey = ValueKey('questSheet.costLine');
  static const Key travelLineKey = ValueKey('questSheet.travelLine');
  static const Key blockedReasonKey = ValueKey('questSheet.blockedReason');
  static const Key stateLabelKey = ValueKey('questSheet.stateLabel');
  static const Key abandonKey = ValueKey('questSheet.abandon');
  static const Key descriptionKey = ValueKey('questSheet.description');
  static const Key petPrizeKey = ValueKey('questSheet.petPrize');
  static const Key enemyPortraitKey = ValueKey('questSheet.enemyPortrait');
  static const Key recommendedLootKey = ValueKey('questSheet.recommendedLoot');
  static const String recommendedLootTitle = 'Consigliati';
  static const String abandonLabel = 'Abbandona il gruppo';
  static const Size _minTapTarget = Size(44, 44);
  static const int _petPrizeMaxLines = 3;
  static const double _coinsShare = 0.5;
  static const double _coinsShareBesideItemAndCompanion = 0.35;

  static const double _aspectRatio = 315 / 375;
  static const double _heightMultiplier = 1.5;
  static const EdgeInsets _contentPadding = EdgeInsets.only(
    top: 0.167,
    left: 0.111,
    right: 0.111,
    bottom: 0.13,
  );

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * _heightMultiplier;
    final sheetWidth = sheetHeight * _aspectRatio;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        CachedSvg(
          url: CloudinaryAssets.url(CloudinaryAssets.emptySheet),
          height: sheetHeight,
          width: sheetWidth,
        ),
        if (quest != null) _buildContent(sheetWidth, sheetHeight),
      ],
    );
  }

  Widget _buildContent(double sheetWidth, double sheetHeight) {
    final details = QuestSheetDetails.of(
      quest!,
      viewer: viewer,
      travelPreview: travelPreview,
    );
    return SizedBox(
      width: sheetWidth,
      height: sheetHeight,
      child: Padding(
        padding: EdgeInsets.only(
          top: sheetHeight * _contentPadding.top,
          left: sheetWidth * _contentPadding.left,
          right: sheetWidth * _contentPadding.right,
          bottom: sheetHeight * _contentPadding.bottom,
        ),
        child: Column(
          children: [
            Expanded(flex: 3, child: _buildQuestInfo(details)),
            if (quest!.prizes != null)
              Expanded(flex: 2, child: _buildRewards(details)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestInfo(QuestSheetDetails details) {
    final theme = KlimmeckGuideTheme.instance;
    return Column(
      children: [
        Flexible(
          child: AutoSizeText(
            quest!.infos?.title ?? '',
            maxFontSize: 24,
            minFontSize: 10,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: theme.headlineLarge,
          ),
        ),
        ..._description(theme),
        Expanded(
          flex: 4,
          child: switch (details.family) {
            QuestSheetFamily.combat => _combatBody(details),
            QuestSheetFamily.narrative => _narrativeBody(details),
            QuestSheetFamily.service => _serviceBody(details),
          },
        ),
        if (details.blockedReason != null)
          Text(
            details.blockedReason!,
            key: blockedReasonKey,
            style: theme.bodyLarge.copyWith(color: KlimmeckGuideTheme.bloodRed),
          ),
        if (stateLabel != null)
          Text(stateLabel!, key: stateLabelKey, style: theme.specialText),
        if (onAbandon != null) _abandonAction(theme),
      ],
    );
  }

  /// Annuncio del committente sotto il titolo, in ogni famiglia (D-05).
  List<Widget> _description(KlimmeckGuideTheme theme) {
    final text = quest!.infos?.description;
    if (text == null || text.isEmpty) return const [];
    return [
      Flexible(
        child: SingleChildScrollView(
          child: Text(
            text,
            key: descriptionKey,
            textAlign: TextAlign.center,
            style: theme.bodyLarge.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    ];
  }

  Widget _abandonAction(KlimmeckGuideTheme theme) => Semantics(
    label: abandonLabel,
    button: true,
    child: TextButton(
      key: abandonKey,
      onPressed: onAbandon,
      style: TextButton.styleFrom(
        minimumSize: _minTapTarget,
        foregroundColor: KlimmeckGuideTheme.bloodRed,
        textStyle: theme.bodyLarge,
      ),
      child: const Text(abandonLabel),
    ),
  );

  Widget _combatBody(QuestSheetDetails details) {
    final hasLeftColumn =
        details.enemyLines.isNotEmpty ||
        details.recommendedLootLines.isNotEmpty;
    return Row(
      key: combatFamilyKey,
      children: [
        if (hasLeftColumn) Expanded(child: _enemyColumn(details)),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._timeLine(),
                ..._travelLine(details),
                ..._titleLine(details),
                ..._slotLines(details),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Ritratto del più forte solo se risolvibile (D-03), righe nell'ordine del
  /// BE (D-02), «Consigliati» sotto (D-04).
  Widget _enemyColumn(QuestSheetDetails details) {
    final portraitPath = details.strongestEnemy?.imagePath;
    return Column(
      children: [
        if (EnemyPortrait.canShow(portraitPath))
          Expanded(
            child: EnemyPortrait(
              key: enemyPortraitKey,
              imagePath: portraitPath,
            ),
          ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final line in details.enemyLines)
                  AutoSizeText(
                    line,
                    maxFontSize: 12,
                    minFontSize: 8,
                    textAlign: TextAlign.center,
                    style: KlimmeckGuideTheme.instance.bodyLarge,
                  ),
                ..._recommendedLoot(details),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrativeBody(QuestSheetDetails details) {
    return Column(
      key: narrativeFamilyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (details.loreParagraphs.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                details.loreParagraphs.join('\n\n'),
                style: KlimmeckGuideTheme.instance.bodyLarge,
              ),
            ),
          ),
        ..._costLine(details),
        ..._titleLine(details),
        ..._slotLines(details),
      ],
    );
  }

  Widget _serviceBody(QuestSheetDetails details) {
    return SingleChildScrollView(
      key: serviceFamilyKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._timeLine(),
          ..._travelLine(details),
          ..._titleLine(details),
          ..._recommendedLoot(details),
          ..._slotLines(details),
        ],
      ),
    );
  }

  List<Widget> _recommendedLoot(QuestSheetDetails details) {
    if (details.recommendedLootLines.isEmpty) return const [];
    final theme = KlimmeckGuideTheme.instance;
    return [
      Text(
        recommendedLootTitle,
        key: recommendedLootKey,
        style: theme.specialText,
      ),
      for (final line in details.recommendedLootLines)
        Text(line, style: theme.bodyLarge),
    ];
  }

  List<Widget> _timeLine() {
    final millis = quest!.infos?.timeToComplete;
    if (millis == null) return const [];
    return [
      Text(
        'Tempo richiesto: ${getStringToShowFromDuration(Duration(milliseconds: millis))}',
        style: KlimmeckGuideTheme.instance.bodyLarge,
      ),
    ];
  }

  List<Widget> _titleLine(QuestSheetDetails details) {
    final text = details.requiredTitleText;
    if (text == null) return const [];
    return [
      Text(
        text,
        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
          color: details.isTitleIneligible ? KlimmeckGuideTheme.bloodRed : null,
        ),
      ),
    ];
  }

  List<Widget> _costLine(QuestSheetDetails details) {
    final cost = details.costLine;
    if (cost == null) return const [];
    return [
      Text(
        cost.text,
        key: costLineKey,
        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
          color: cost.isInsufficient ? KlimmeckGuideTheme.bloodRed : null,
        ),
      ),
    ];
  }

  /// Riga «Viaggio» nella posizione dei costi (D-04): rossa con la frase
  /// dell'utente quando il personaggio non arriverebbe vivo.
  List<Widget> _travelLine(QuestSheetDetails details) {
    final line = details.travelLine;
    if (line == null) return const [];
    return [
      Text(
        line.text,
        key: travelLineKey,
        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
          color: line.isStarving ? KlimmeckGuideTheme.bloodRed : null,
        ),
      ),
    ];
  }

  List<Widget> _slotLines(QuestSheetDetails details) => [
    for (final line in details.slotLines)
      Text(
        line.text,
        style: line.isViewerRank
            ? KlimmeckGuideTheme.instance.specialText
            : KlimmeckGuideTheme.instance.bodyLarge,
      ),
  ];

  Widget _buildRewards(QuestSheetDetails details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 30,
          child: AutoSizeText(
            "Ricompense:",
            maxFontSize: 20,
            minFontSize: 10,
            textAlign: TextAlign.left,
            style: KlimmeckGuideTheme.instance.specialText,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => _prizeRow(details, constraints),
          ),
        ),
      ],
    );
  }

  /// Il compagno sta nella riga dei premi: sotto, le monete non ci stanno (D-06).
  /// La carta resta quadrata; con oggetto e compagno le monete cedono spazio.
  Widget _prizeRow(QuestSheetDetails details, BoxConstraints constraints) {
    final prizes = quest!.prizes!;
    final hasItemAndCompanion =
        prizes.prizeItem != null && details.petPrizeLine != null;
    final coinsShare = hasItemAndCompanion
        ? _coinsShareBesideItemAndCompanion
        : _coinsShare;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (prizes.prizeCoins != null)
          CoinsDisplay(
            coins: prizes.prizeCoins!,
            height: constraints.maxHeight,
            width: constraints.maxWidth * coinsShare,
          ),
        if (prizes.prizeItem != null)
          SizedBox(
            width: constraints.maxHeight,
            child: prizes.prizeItem!.isEquipment
                ? EquipmentItemCard(
                    isSelected: false,
                    size: constraints.maxHeight,
                    equipmentItem: prizes.prizeItem!.asEquipment!,
                  )
                : LootItemCard(
                    lootItem: prizes.prizeItem!.asLoot!,
                    size: constraints.maxHeight,
                  ),
          ),
        if (details.petPrizeLine != null)
          Flexible(
            child: Text(
              details.petPrizeLine!,
              key: petPrizeKey,
              maxLines: _petPrizeMaxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: KlimmeckGuideTheme.instance.bodyLarge,
            ),
          ),
      ],
    );
  }
}
