import 'dart:math' show max, min;
import 'dart:ui' show ImageFilter;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_details_gesture.dart';
import 'package:klimmeck_guide/shared/components/cards/loot_item_card.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/enemy_portrait.dart';
import 'package:klimmeck_guide/shared/components/popup/companion_details_route.dart';
import 'package:klimmeck_guide/shared/components/title_badge.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';
import 'package:klimmeck_guide/utils/prison_lines.dart';

import '../../../models/enums/injury_type.dart';
import '../../../models/enums/title_type.dart';
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
    this.characterInjuries,
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

  /// Ferite del personaggio che guarda (Bacheca e Mappa, D-19): servono solo
  /// alla riga della cura. Null = ferite ignote, nessuna riga della cura.
  final List<InjuryType>? characterInjuries;

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
  static const Key cureLineKey = ValueKey('questSheet.cureLine');
  static const Key lifeLineKey = ValueKey('questSheet.lifeLine');
  static const Key sheetAreaKey = ValueKey('questSheet.sheetArea');
  static const Key requiredTitleKey = ValueKey('questSheet.requiredTitle');
  static Key slotLineKeyOf(TitleType title) =>
      ValueKey('questSheet.slotLine.${title.name}');

  /// Badge del titolo nell'angolo in alto a sinistra del foglio: lato e
  /// distanze dai bordi come frazioni della larghezza del foglio (posizione
  /// scelta dall'utente sul telefono, revisione layout 2026-11-17).
  static const double _titleBadgeShare = 0.2;
  static const double _titleBadgeLeftInset = 0.096;
  static const double _titleBadgeTopInset = 0.176;
  static const Offset _titleBadgeShadowOffset = Offset(2, 4);
  static const double _titleBadgeShadowBlur = 5;
  static const Color _titleBadgeShadowColor = Color(0x99000000);
  static const double _ineligibleRingWidth = 2;
  static const String recommendedLootTitle = 'Consigliati';
  static const String abandonLabel = 'Abbandona il gruppo';
  static const Size _minTapTarget = Size(44, 44);
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

    final details = quest == null
        ? null
        : QuestSheetDetails.of(
            quest!,
            viewer: viewer,
            travelPreview: travelPreview,
          );

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        CachedSvg(
          url: CloudinaryAssets.url(CloudinaryAssets.emptySheet),
          height: sheetHeight,
          width: sheetWidth,
        ),
        if (details != null)
          SizedBox(
            key: sheetAreaKey,
            width: sheetWidth,
            height: sheetHeight,
            child: Stack(
              children: [
                _buildContent(details, sheetWidth, sheetHeight),
                if (details.requiredTitle case final title?)
                  Positioned(
                    left: sheetWidth * _titleBadgeLeftInset,
                    top: sheetWidth * _titleBadgeTopInset,
                    child: _titleBadge(
                      details,
                      title,
                      sheetWidth * _titleBadgeShare,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContent(
    QuestSheetDetails details,
    double sheetWidth,
    double sheetHeight,
  ) {
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
        if (_blockedReasonOf(details) case final reason?)
          Text(
            reason,
            key: blockedReasonKey,
            style: theme.bodyLarge.copyWith(color: KlimmeckGuideTheme.bloodRed),
          ),
        if (stateLabel != null)
          Text(stateLabel!, key: stateLabelKey, style: theme.specialText),
        if (onAbandon != null) _abandonAction(theme),
      ],
    );
  }

  /// In prigione la riga dice anche il tempo che manca (quick 261110-cgd).
  String? _blockedReasonOf(QuestSheetDetails details) => details.isImprisoned
      ? prisonReleaseLine(viewer?.imprisonedFor)
      : details.blockedReason;

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
                ..._cureLines(),
                ..._travelLine(details),
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
              known: details.isStrongestEnemyKnown,
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

  /// Lore e righe della cura scorrono insieme; costo e posti restano fermi in
  /// fondo al foglio.
  Widget _narrativeBody(QuestSheetDetails details) {
    final hasLore = details.loreParagraphs.isNotEmpty;
    final cureLines = _cureLines();
    return Column(
      key: narrativeFamilyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLore || cureLines.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasLore)
                    Text(
                      details.loreParagraphs.join('\n\n'),
                      style: KlimmeckGuideTheme.instance.bodyLarge,
                    ),
                  ...cureLines,
                ],
              ),
            ),
          ),
        ..._costLine(details),
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
          ..._cureLines(),
          ..._travelLine(details),
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
        'Tempo richiesto: ${formatQuestDuration(Duration(milliseconds: millis))}',
        style: KlimmeckGuideTheme.instance.bodyLarge,
      ),
    ];
  }

  /// Righe della cura (D-03, D-04): presenti per ogni quest che porta una
  /// cura, in ogni famiglia di foglio (D-05). Le stringhe nascono qui, nel
  /// widget, dagli helper puri delle righe (D-21).
  List<Widget> _cureLines() {
    final cure = quest!.prizes?.cure;
    final style = KlimmeckGuideTheme.instance.bodyLarge;
    return [
      if (curableInjuriesLine(cure, characterInjuries) case final line?)
        Text(line, key: cureLineKey, style: style),
      if (lifeShareLine(cure) case final line?)
        Text(line, key: lifeLineKey, style: style),
    ];
  }

  /// Badge del titolo che serve, al posto della frase; cerchiato di rosso
  /// quando chi guarda non ce l'ha.
  Widget _titleBadge(QuestSheetDetails details, TitleType title, double size) {
    return Container(
      key: requiredTitleKey,
      decoration: details.isTitleIneligible
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: KlimmeckGuideTheme.bloodRed,
                width: _ineligibleRingWidth,
              ),
            )
          : null,
      child: Stack(
        children: [
          _titleBadgeShadow(title, size),
          TitleBadge(
            title: title,
            size: size,
            semanticLabel: details.requiredTitleText,
          ),
        ],
      ),
    );
  }

  /// Ombra sfumata dietro il badge: la sua stessa sagoma, scurita e sfocata,
  /// così segue il tondo come il rombo.
  Widget _titleBadgeShadow(TitleType title, double size) => Transform.translate(
    offset: _titleBadgeShadowOffset,
    child: ExcludeSemantics(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: _titleBadgeShadowBlur,
          sigmaY: _titleBadgeShadowBlur,
        ),
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            _titleBadgeShadowColor,
            BlendMode.srcIn,
          ),
          child: CachedSvg(url: title.badgePath, width: size, height: size),
        ),
      ),
    ),
  );

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

  /// Posti affiancati: coi badge stanno su una riga sola.
  List<Widget> _slotLines(QuestSheetDetails details) {
    if (details.slotLines.isEmpty) return const [];
    return [
      Wrap(
        spacing: KlimmeckGuideTheme.spacingSm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [for (final line in details.slotLines) _slotLine(line)],
      ),
    ];
  }

  /// Posti di un titolo: il suo badge e i posti presi; i posti di qualsiasi
  /// rango non hanno badge e restano scritti.
  Widget _slotLine(QuestSlotLine line) {
    final style = line.isViewerRank
        ? KlimmeckGuideTheme.instance.specialText
        : KlimmeckGuideTheme.instance.bodyLarge;
    final title = line.title;
    if (title == null) return Text(line.text, style: style);
    return Row(
      key: slotLineKeyOf(title),
      mainAxisSize: MainAxisSize.min,
      children: [
        TitleBadge(title: title),
        const SizedBox(width: KlimmeckGuideTheme.spacingXs),
        Text(line.seatsText, style: style),
      ],
    );
  }

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
            builder: (context, constraints) =>
                _prizeRow(context, details, constraints),
          ),
        ),
      ],
    );
  }

  /// Il compagno sta nella riga dei premi: sotto, le monete non ci stanno (D-06).
  /// Le carte restano quadrate; con oggetto e compagno le monete cedono spazio
  /// e non vanno mai oltre quello che le carte lasciano (Phase 22 D-35).
  Widget _prizeRow(
    BuildContext context,
    QuestSheetDetails details,
    BoxConstraints constraints,
  ) {
    final prizes = quest!.prizes!;
    final hasItemAndCompanion =
        prizes.prizeItem != null && details.petPrize != null;
    final coinsShare = hasItemAndCompanion
        ? _coinsShareBesideItemAndCompanion
        : _coinsShare;
    final cardCount = [prizes.prizeItem, details.petPrize].nonNulls.length;
    final coinsWidth = min(
      constraints.maxWidth * coinsShare,
      max(0.0, constraints.maxWidth - cardCount * constraints.maxHeight),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (prizes.prizeCoins != null)
          CoinsDisplay(
            coins: prizes.prizeCoins!,
            height: constraints.maxHeight,
            width: coinsWidth,
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
        if (details.petPrize case final pet?)
          SizedBox(
            key: petPrizeKey,
            width: constraints.maxHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: companionDetailsGesture(
                pet,
                () => showCompanionDetails(context, pet: pet),
              ),
              child: CompanionCard(pet: pet, size: constraints.maxHeight),
            ),
          ),
      ],
    );
  }
}
