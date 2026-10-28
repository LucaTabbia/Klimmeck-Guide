import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/enums/column_layout_type.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/quest_result/quest_outcome.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/hp_delta_bar.dart';
import 'package:klimmeck_guide/shared/components/item_row.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Foglio esiti a tutto schermo (09-CONTEXT D-01..D-05, D-14): un solo widget
/// per i cinque esiti, sezioni senza dati non costruite. Puro: niente route,
/// niente cubit; il presenter (piano 09-10) apre il dialog e conferma.
class QuestResultSheet extends StatefulWidget {
  const QuestResultSheet({
    super.key,
    required this.result,
    required this.onContinue,
    this.characterName,
    this.position = 1,
    this.total = 1,
    this.isAcknowledging = false,
    this.hasAcknowledgeFailed = false,
  });

  static const Key headerKey = ValueKey('questResult.header');
  static const Key questTypeKey = ValueKey('questResult.questType');
  static const Key deadNameKey = ValueKey('questResult.deadName');
  static const Key enemyKey = ValueKey('questResult.enemy');
  static const Key hpKey = ValueKey('questResult.hp');
  static const Key injuriesKey = ValueKey('questResult.injuries');
  static const Key consumablesKey = ValueKey('questResult.consumables');
  static const Key spellsKey = ValueKey('questResult.spells');
  static const Key rewardsKey = ValueKey('questResult.rewards');
  static const Key xpKey = ValueKey('questResult.xp');
  static const Key levelKey = ValueKey('questResult.level');
  static const Key titleKey = ValueKey('questResult.title');
  static const Key spellLearnedKey = ValueKey('questResult.spellLearned');
  static const Key rescuedKey = ValueKey('questResult.rescued');
  static const Key counterKey = ValueKey('questResult.counter');
  static const Key continueKey = ValueKey('questResult.continue');
  static const Key acknowledgeErrorKey = ValueKey(
    'questResult.acknowledgeError',
  );
  static const Duration hpAnimationDuration = Duration(milliseconds: 1200);

  final QuestResult result;

  /// Unica chiusura del foglio (D-05): il presenter conferma e passa al successivo.
  final VoidCallback onContinue;

  /// Nome del personaggio morto (D-14), noto solo se è il personaggio della shell.
  final String? characterName;

  /// Posizione nella coda dei fogli (D-08): il contatore appare se `total > 1`.
  final int position;
  final int total;

  /// Conferma della morte in corso: il pulsante è disabilitato (D-10).
  final bool isAcknowledging;

  /// Conferma fallita: riga d'errore, il pulsante resta per riprovare (D-10).
  final bool hasAcknowledgeFailed;

  @override
  State<QuestResultSheet> createState() => _QuestResultSheetState();
}

class _QuestResultSheetState extends State<QuestResultSheet> {
  static const double _aspectRatio = 315 / 375;
  static const EdgeInsets _contentPadding = EdgeInsets.only(
    top: 0.167,
    left: 0.111,
    right: 0.111,
    bottom: 0.13,
  );
  static const double _enemyImageHeight = 48;
  static const double _itemSize = 40;
  static const double _coinsHeight = 24;
  static const Size _minTapTarget = Size(44, 44);
  static const String _unknownSpell = 'Magia sconosciuta';
  static final DateFormat _resolvedAtFormat = DateFormat('dd/MM HH:mm');

  bool _isSkipped = false;

  QuestResult get _result => widget.result;
  KlimmeckGuideTheme get _theme => KlimmeckGuideTheme.instance;

  void _skipAnimation() {
    if (_isSkipped) return;
    setState(() => _isSkipped = true);
  }

  /// Entrambi i lati dal vincolo più stretto: il riquadro resta nel rapporto
  /// della pergamena anche su una finestra stretta (09-REVIEW WR-02).
  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sheetWidth = math.min(
            constraints.maxWidth,
            constraints.maxHeight * _aspectRatio,
          );
          final sheetHeight = sheetWidth / _aspectRatio;
          return SizedBox(
            width: sheetWidth,
            height: sheetHeight,
            child: Stack(
              children: [
                CachedSvg(
                  url: CloudinaryAssets.url(CloudinaryAssets.emptySheet),
                  height: sheetHeight,
                  width: sheetWidth,
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: sheetHeight * _contentPadding.top,
                    left: sheetWidth * _contentPadding.left,
                    right: sheetWidth * _contentPadding.right,
                    bottom: sheetHeight * _contentPadding.bottom,
                  ),
                  child: Column(
                    children: [
                      Expanded(child: _content()),
                      ..._footer(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _content() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._header(),
        ..._deathIdentity(),
        ..._enemy(),
        ..._hp(),
        ..._injuries(),
        ..._consumables(),
        ..._spells(),
        ..._rewards(),
        ..._line(_xpText(), QuestResultSheet.xpKey),
        ..._line(_levelText(), QuestResultSheet.levelKey),
        ..._line(_titleText(), QuestResultSheet.titleKey),
        ..._line(_spellLearnedText(), QuestResultSheet.spellLearnedKey),
        ..._line(_rescuedText(), QuestResultSheet.rescuedKey),
      ],
    ),
  );

  List<Widget> _header() {
    final type = _result.quest.type;
    return [
      Text(
        _result.outcome.label,
        key: QuestResultSheet.headerKey,
        textAlign: TextAlign.center,
        style: _theme.titleMedium.copyWith(color: _outcomeInk),
      ),
      Text(
        _result.quest.title,
        textAlign: TextAlign.center,
        style: _theme.bodyMedium,
      ),
      if (type != null)
        Text(
          type.label,
          key: QuestResultSheet.questTypeKey,
          textAlign: TextAlign.center,
          style: _theme.bodyMedium,
        ),
      Text(
        _resolvedAtFormat.format(_result.resolvedAt.toLocal()),
        textAlign: TextAlign.center,
        style: _theme.bodyMedium,
      ),
    ];
  }

  Color get _outcomeInk => switch (_result.outcome) {
    QuestOutcome.success ||
    QuestOutcome.gmCompleted => KlimmeckGuideTheme.darkBronze,
    QuestOutcome.failure => KlimmeckGuideTheme.royalCrimson,
    QuestOutcome.rescued => KlimmeckGuideTheme.mysticBlue,
    QuestOutcome.death => KlimmeckGuideTheme.deepNight,
  };

  List<Widget> _deathIdentity() {
    if (!_result.isDeath) return const [];
    final name = widget.characterName;
    final title = _result.titleAfter?.label;
    final level = 'Livello ${_result.levelAfter}';
    return [
      if (name != null)
        Text(
          name,
          key: QuestResultSheet.deadNameKey,
          textAlign: TextAlign.center,
          style: _theme.titleMedium,
        ),
      Text(
        title == null ? level : '$title · $level',
        textAlign: TextAlign.center,
        style: _theme.bodyMedium,
      ),
    ];
  }

  List<Widget> _enemy() {
    final enemy = _result.enemy;
    if (enemy == null) return const [];
    return [
      Column(
        key: QuestResultSheet.enemyKey,
        children: [
          if (enemy.imagePath != null)
            SizedBox(
              height: _enemyImageHeight,
              child: Image.asset(
                enemy.imagePath!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Text(
            enemy.name ?? '',
            textAlign: TextAlign.center,
            style: _theme.bodyMedium,
          ),
        ],
      ),
    ];
  }

  List<Widget> _hp() {
    if (_result.outcome == QuestOutcome.rescued || _result.isDeath) {
      return const [];
    }
    final before = _result.hpBefore;
    final after = _result.hpAfter;
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          vertical: KlimmeckGuideTheme.spacingSm,
        ),
        child: GestureDetector(
          key: QuestResultSheet.hpKey,
          behavior: HitTestBehavior.opaque,
          onTap: _skipAnimation,
          child: TweenAnimationBuilder<double>(
            key: ValueKey<bool>(_isSkipped),
            tween: Tween(
              begin: (_isSkipped ? after : before).toDouble(),
              end: after.toDouble(),
            ),
            duration: QuestResultSheet.hpAnimationDuration,
            builder: (_, hp, _) => HpDeltaBar(
              hp: hp,
              max: _result.maxLifePoints,
              isLoss: after < before,
              isGain: after > before,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _injuries() => _section(
    key: QuestResultSheet.injuriesKey,
    title: 'Ferite',
    children: [
      for (final injury in _result.injuriesAdded)
        Text(injury.label, style: _theme.bodyMedium),
    ],
  );

  List<Widget> _consumables() => _section(
    key: QuestResultSheet.consumablesKey,
    title: 'Consumabili usati',
    children: _itemRows(_result.consumablesUsed),
  );

  List<Widget> _spells() => _section(
    key: QuestResultSheet.spellsKey,
    title: 'Magie usate',
    children: [
      for (final usage in _result.spellsUsed)
        Text(
          '${usage.spell?.name ?? _unknownSpell} ×${usage.usages}',
          style: _theme.bodyMedium,
        ),
    ],
  );

  List<Widget> _rewards() {
    if (!_result.hasRewards) return const [];
    final coins = _result.rewards.coins;
    return _section(
      key: QuestResultSheet.rewardsKey,
      title: 'Ricompense',
      children: [
        if (coins.toCopper() > 0)
          CoinsDisplay(
            coins: coins,
            height: _coinsHeight,
            layout: CoinLayoutType.row,
          ),
        ..._itemRows(_result.rewards.items),
      ],
    );
  }

  List<Widget> _itemRows(List<AssetQuantity> entries) => [
    for (final entry in entries)
      if (entry.item != null)
        ItemRow(
          assetItem: entry.item!,
          quantity: entry.quantity,
          showCoins: false,
          size: _itemSize,
        ),
  ];

  List<Widget> _section({
    required Key key,
    required String title,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return const [];
    return [
      Padding(
        key: key,
        padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: _theme.titleMedium),
            ...children,
          ],
        ),
      ),
    ];
  }

  List<Widget> _line(String? text, Key key) {
    if (text == null) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingSm),
        child: Text(text, key: key, style: _theme.bodyMedium),
      ),
    ];
  }

  String? _xpText() {
    if (_result.xpGained <= 0) return null;
    return 'Esperienza: ${_result.xpBefore} → ${_result.xpAfter} '
        '(+${_result.xpGained})';
  }

  String? _levelText() {
    if (!_result.hasLevelChanged) return null;
    return 'Livello ${_result.levelBefore} → ${_result.levelAfter}';
  }

  String? _titleText() {
    final before = _result.titleBefore;
    final after = _result.titleAfter;
    if (!_result.hasTitleChanged || before == null || after == null) {
      return null;
    }
    return '${before.label} → ${after.label}';
  }

  String? _spellLearnedText() {
    final spell = _result.spellLearned;
    if (spell == null) return null;
    return 'Magia appresa: ${spell.name}';
  }

  String? _rescuedText() {
    final count = _result.rescuedCharacters.length;
    if (count == 0) return null;
    final noun = count == 1 ? 'avventuriero' : 'avventurieri';
    return 'Hai salvato $count $noun';
  }

  List<Widget> _footer() => [
    if (widget.total > 1)
      Text(
        '${widget.position} di ${widget.total}',
        key: QuestResultSheet.counterKey,
        style: _theme.bodyMedium,
      ),
    if (widget.hasAcknowledgeFailed)
      Text(
        'Conferma non riuscita: riprova',
        key: QuestResultSheet.acknowledgeErrorKey,
        textAlign: TextAlign.center,
        style: _theme.bodyMedium.copyWith(color: KlimmeckGuideTheme.bloodRed),
      ),
    _continueButton(),
  ];

  Widget _continueButton() => TextButton(
    key: QuestResultSheet.continueKey,
    onPressed: widget.isAcknowledging ? null : widget.onContinue,
    style: TextButton.styleFrom(
      minimumSize: _minTapTarget,
      foregroundColor: _result.isDeath
          ? KlimmeckGuideTheme.deepNight
          : KlimmeckGuideTheme.darkWood,
      textStyle: _theme.titleMedium,
    ),
    child: Text(_result.isDeath ? 'Riposa in pace' : 'Continua'),
  );
}
