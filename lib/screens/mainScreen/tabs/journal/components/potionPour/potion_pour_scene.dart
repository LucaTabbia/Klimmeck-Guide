import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/config/potion_bottle_geometry.dart';
import 'package:klimmeck_guide/models/companion/companion_potion_target.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit.dart';
import 'package:klimmeck_guide/shared/components/healed_injuries_text.dart';
import 'package:klimmeck_guide/shared/components/hp_delta_bar.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/enemy_portrait_url.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';
import 'package:klimmeck_guide/utils/lore_lines.dart';
import 'package:klimmeck_guide/utils/potion_liquid_color.dart';
import 'package:klimmeck_guide/utils/pour_geometry.dart';
import 'package:klimmeck_guide/utils/pour_simulation.dart';
import 'package:klimmeck_guide/utils/race_figure_url.dart';

import 'potion_bottle_images.dart';
import 'potion_bottle_painter.dart';
import 'potion_drinker_figure.dart';

export 'potion_drinker_figure.dart';

/// La scena sopra il Diario: trasparente, i cubit passati per valore perché
/// la route vive sul navigator radice, fuori dai provider della shell.
Route<void> potionPourRoute({
  required PotionCubit potionCubit,
  required PotionRecoveryCubit recoveryCubit,
  required PotionPourScene scene,
}) => PageRouteBuilder<void>(
  opaque: false,
  barrierColor: KlimmeckGuideTheme.disabledScrim,
  transitionDuration: const Duration(milliseconds: 250),
  reverseTransitionDuration: const Duration(milliseconds: 200),
  pageBuilder: (_, _, _) => MultiBlocProvider(
    providers: [
      BlocProvider<PotionCubit>.value(value: potionCubit),
      BlocProvider<PotionRecoveryCubit>.value(value: recoveryCubit),
    ],
    child: Material(type: MaterialType.transparency, child: scene),
  ),
  transitionsBuilder: (_, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
);

/// Una pozione si beve con un gesto, senza pulsanti né parole da toccare
/// (Phase 26): la boccetta al centro si trascina verso chi beve, si inclina e
/// alla prima goccia la pozione è data. Il personaggio sta fisso a destra
/// (se non è in ricarica), i compagni che possono bere a sinistra, uno alla
/// volta, scorrendo in verticale. Tocco fuori = la boccetta torna nella
/// borsa; tocco prolungato = cosa cura e quanto dura la ricarica.
class PotionPourScene extends StatefulWidget {
  const PotionPourScene({
    super.key,
    required this.item,
    required this.race,
    required this.sex,
    required this.maxLifePoints,
    this.companions = const [],
    this.readerInnkeeperInjuries = const [],
  });

  final LootItem item;
  final RaceType? race;
  final SexType? sex;

  /// Vita massima del personaggio letta all'apertura: l'esito non la porta.
  final int? maxLifePoints;

  /// Compagni che possono bere, letti all'apertura (Phase 22 D-07, D-08).
  final List<CompanionPotionTarget> companions;

  /// Ferite dell'oste del personaggio: in rosso dentro «Cura: …» (D-21).
  final List<InjuryType> readerInnkeeperInjuries;

  static const Key bottleKey = ValueKey('potionPour.bottle');
  static const Key characterKey = ValueKey('potionPour.character');
  static const Key companionsKey = ValueKey('potionPour.companions');
  static const Key detailsKey = ValueKey('potionPour.details');
  static const Key hpKey = ValueKey('potionPour.hp');
  static const Key healedKey = ValueKey('potionPour.healed');
  static Key companionKeyOf(String petId) =>
      ValueKey('potionPour.companion.$petId');
  static Key loreKeyOf(String loreId) => ValueKey('potionPour.lore.$loreId');

  static const Duration hpAnimationDuration = Duration(milliseconds: 900);

  /// L'esito resta a schermo due secondi dopo che la barra si è riempita,
  /// poi la scena si chiude da sola.
  static const Duration outcomeCloseDelay = Duration(milliseconds: 900 + 2000);

  @override
  State<PotionPourScene> createState() => _PotionPourSceneState();
}

class _PotionPourSceneState extends State<PotionPourScene>
    with SingleTickerProviderStateMixin {
  static const double _bottleHeightShare = 0.62;
  static const double _sideShare = 0.3;
  static const double _fullTiltShare = 0.26;
  static const double _dragLimitShare = 0.3;
  static const double _returnSpeed = 10;
  static const Duration _corkFlight = Duration(milliseconds: 450);

  late final Ticker _ticker;
  Timer? _outcomeClose;
  final PageController _companionPages = PageController();
  PotionBottleImages? _images;
  PourSimulation? _simulation;
  Size? _bottleSize;
  Duration _lastTick = Duration.zero;
  Offset _drag = Offset.zero;
  bool _isDragging = false;
  bool _isShowingDetails = false;
  double _corkLift = 0;
  bool _isCorkFlying = false;
  int _companionIndex = 0;

  bool get _canCharacterDrink =>
      !context.read<PotionRecoveryCubit>().state.isRecovering;

  bool get _isCommitted => _simulation?.committedSide != null;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    PotionBottleImages.load(rootBundle).then((images) {
      if (mounted) setState(() => _images = images);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _outcomeClose?.cancel();
    _companionPages.dispose();
    super.dispose();
  }

  Set<PourSide> get _sides => {
    if (_canCharacterDrink) PourSide.character,
    if (widget.companions.isNotEmpty) PourSide.companion,
  };

  PourSimulation _simulationFor(Size bottleSize) {
    final existing = _simulation;
    if (existing != null && bottleSize == _bottleSize) return existing;
    _bottleSize = bottleSize;
    return _simulation = PourSimulation(
      geometry: PourGeometry(
        interior: [
          for (final point in PotionBottleGeometry.interior)
            Offset(point.dx * bottleSize.width, point.dy * bottleSize.height),
        ],
        mouth: Offset(
          PotionBottleGeometry.mouth.dx * bottleSize.width,
          PotionBottleGeometry.mouth.dy * bottleSize.height,
        ),
        pivot: Offset(bottleSize.width / 2, bottleSize.height / 2),
      ),
      sides: _sides,
      fill: existing?.fill ?? PourSimulation.startFill,
    );
  }

  void _onTick(Duration elapsed) {
    final simulation = _simulation;
    final dt = elapsed - _lastTick;
    _lastTick = elapsed;
    if (simulation == null || dt == Duration.zero) return;
    final seconds = dt.inMicroseconds / Duration.microsecondsPerSecond;
    if (!_isDragging && !_isCommitted) {
      _drag = Offset.lerp(
        _drag,
        Offset.zero,
        (_returnSpeed * seconds).clamp(0, 1),
      )!;
    }
    if (_isCorkFlying && _corkLift < 1) {
      _corkLift = (_corkLift + seconds / (_corkFlight.inMilliseconds / 1000))
          .clamp(0, 1);
    }
    if (simulation.step(dt) case final side?) _commit(side);
    setState(() {});
    _closeOutcomeLater();
    if (_isAtRest(simulation)) _stopTicking();
  }

  /// Ferma e senza nulla in volo: il ticker si spegne finché il dito non
  /// torna sulla boccetta.
  bool _isAtRest(PourSimulation simulation) {
    final isCorkMoving = _isCorkFlying && _corkLift < 1;
    if (simulation.isEmpty) return !isCorkMoving;
    return !_isDragging &&
        !isCorkMoving &&
        !_isCommitted &&
        _drag.distance < 0.5 &&
        simulation.isSettled;
  }

  void _startTicking() {
    if (!_ticker.isActive) _ticker.start();
  }

  void _stopTicking() {
    _ticker.stop();
    _lastTick = Duration.zero;
  }

  void _commit(PourSide side) {
    HapticFeedback.mediumImpact();
    final cubit = context.read<PotionCubit>();
    switch (side) {
      case PourSide.character:
        cubit.drink(widget.item.id);
      case PourSide.companion:
        final target = widget.companions[_companionIndex];
        cubit.give(
          widget.item.id,
          petId: target.petId,
          targetName: target.name,
        );
    }
  }

  void _onPanStart(DragStartDetails _) {
    if (_isCommitted) return;
    _isDragging = true;
    _isCorkFlying = true;
    _startTicking();
  }

  void _onPanUpdate(DragUpdateDetails details, Size scene) {
    if (_isCommitted) return;
    final limit = Offset(
      scene.width * _dragLimitShare,
      scene.height * _dragLimitShare,
    );
    final moved = _drag + details.delta;
    _drag = Offset(
      moved.dx.clamp(-limit.dx, limit.dx),
      moved.dy.clamp(-limit.dy, limit.dy),
    );
    _simulation?.aim(
      _drag.dx / (scene.width * _fullTiltShare) * PourSimulation.maxTilt,
    );
  }

  void _onPanEnd() {
    _isDragging = false;
    _simulation?.aim(0);
  }

  /// Tocco fuori dalla boccetta: prima della prima goccia la rimette nella
  /// borsa, a esito mostrato chiude; mai mentre la pozione è in volo.
  void _leave() {
    final isInFlight = context.read<PotionCubit>().state is PotionDrinking;
    if (isInFlight) return;
    if (_isCommitted && _drunkResult() == null) return;
    Navigator.of(context).maybePop();
  }

  PotionDrunk? _drunkResult() {
    final state = context.read<PotionCubit>().state;
    if (state is PotionDrunk && state.itemId == widget.item.id) return state;
    return null;
  }

  @override
  Widget build(BuildContext context) => BlocListener<PotionCubit, PotionState>(
    listenWhen: (_, current) =>
        current is PotionRefused || current is PotionDrunk,
    listener: (context, state) => state is PotionRefused
        ? Navigator.of(context).pop()
        : _closeOutcomeLater(),
    child: BlocBuilder<PotionCubit, PotionState>(
      builder: (context, state) => PopScope(
        canPop: !_isCommitted || _outcomeOf(state) != null,
        child: LayoutBuilder(
          builder: (context, constraints) =>
              _scene(context, constraints.biggest),
        ),
      ),
    ),
  );

  /// Esito a schermo per la prima volta: la chiusura parte da sola.
  void _closeOutcomeLater() {
    if (_outcomeClose != null) return;
    if (_outcomeOf(context.read<PotionCubit>().state) == null) return;
    _outcomeClose = Timer(PotionPourScene.outcomeCloseDelay, () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  PotionDrunk? _outcomeOf(PotionState state) {
    final simulation = _simulation;
    if (simulation == null || !simulation.isEmpty) return null;
    if (state is PotionDrunk && state.itemId == widget.item.id) return state;
    return null;
  }

  Widget _scene(BuildContext context, Size scene) {
    final bottleHeight = scene.height * _bottleHeightShare;
    final bottleSize = Size(
      bottleHeight *
          PotionBottleGeometry.imageSize.width /
          PotionBottleGeometry.imageSize.height,
      bottleHeight,
    );
    final simulation = _simulationFor(bottleSize);
    final center = scene.center(Offset.zero) + _drag;
    final outcome = _outcomeOf(context.read<PotionCubit>().state);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _leave,
          ),
        ),
        if (widget.companions.isNotEmpty) _companionsSide(scene),
        if (_canCharacterDrink) _characterSide(scene),
        Positioned.fill(
          child: IgnorePointer(
            // Il multiply del liquido non accetta l'opacità ereditata dalla
            // dissolvenza della route: Impeller la vuole su un layer suo.
            child: RepaintBoundary(
              child: CustomPaint(
                painter: PotionBottlePainter(
                  images: _images,
                  center: center,
                  boxSize: bottleSize,
                  angle: simulation.angle,
                  level: simulation.level,
                  slosh: simulation.slosh,
                  wavePhase: simulation.wavePhase,
                  isPouring:
                      _isCommitted &&
                      !simulation.isEmpty &&
                      simulation.level.isSpilling,
                  isCorked: !_isCorkFlying,
                  corkLift: _corkLift,
                  liquidColor: potionLiquidColorOf(widget.item.rarity),
                  name: widget.item.name ?? '',
                  nameStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: KlimmeckGuideTheme.darkWood,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: center.dx - bottleSize.width / 2,
          top: center.dy - bottleSize.height / 2,
          width: bottleSize.width,
          height: bottleSize.height,
          child: GestureDetector(
            key: PotionPourScene.bottleKey,
            behavior: HitTestBehavior.opaque,
            onPanStart: _onPanStart,
            onPanUpdate: (details) => _onPanUpdate(details, scene),
            onPanEnd: (_) => _onPanEnd(),
            onPanCancel: _onPanEnd,
            onLongPressStart: (_) => setState(() => _isShowingDetails = true),
            onLongPressEnd: (_) => setState(() => _isShowingDetails = false),
          ),
        ),
        if (_isShowingDetails && !_isCommitted) _details(context, scene),
        ?_outcome(context, outcome),
      ],
    );
  }

  Widget _companionsSide(Size scene) => Positioned(
    left: 0,
    top: 0,
    bottom: 0,
    width: scene.width * _sideShare,
    child: PageView.builder(
      key: PotionPourScene.companionsKey,
      controller: _companionPages,
      scrollDirection: Axis.vertical,
      physics: _isCommitted
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      itemCount: widget.companions.length,
      onPageChanged: (index) => _companionIndex = index,
      itemBuilder: (_, index) {
        final companion = widget.companions[index];
        return PotionDrinkerFigure(
          key: PotionPourScene.companionKeyOf(companion.petId),
          url: enemyPortraitUrl(companion.owned.pet.imagePath),
          standsOnLeft: true,
        );
      },
    ),
  );

  Widget _characterSide(Size scene) {
    final race = widget.race;
    final sex = widget.sex;
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: scene.width * _sideShare,
      child: IgnorePointer(
        child: PotionDrinkerFigure(
          key: PotionPourScene.characterKey,
          url: race == null || sex == null ? null : raceFigureUrl(race, sex),
          standsOnLeft: false,
        ),
      ),
    );
  }

  Widget _details(BuildContext context, Size scene) {
    final textTheme = Theme.of(context).textTheme;
    final healed = healedInjuryLabels(
      widget.item,
      beyondCure: widget.readerInnkeeperInjuries,
    );
    return Positioned(
      left: scene.width * _sideShare,
      right: scene.width * _sideShare,
      bottom: KlimmeckGuideTheme.spacingMd,
      child: IgnorePointer(
        child: Column(
          key: PotionPourScene.detailsKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (healed.isNotEmpty)
              HealedInjuriesText(
                labels: healed,
                style: textTheme.bodyMedium?.copyWith(
                  color: KlimmeckGuideTheme.parchment,
                ),
                textAlign: TextAlign.center,
              ),
            if (recoveryLine(widget.item.recovery) case final recovery?)
              Text(
                recovery,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: KlimmeckGuideTheme.parchment,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _outcome(BuildContext context, PotionDrunk? drunk) {
    if (drunk == null) return null;
    final textTheme = Theme.of(context).textTheme;
    final lineStyle = textTheme.bodyMedium?.copyWith(
      color: KlimmeckGuideTheme.parchment,
      shadows: KlimmeckGuideTheme.bordersForText,
    );
    final targetPetId = drunk.targetPetId;
    final max = targetPetId == null
        ? widget.maxLifePoints
        : _companionMaxOf(targetPetId);
    final healed = targetPetId == null
        ? healedLine(drunk.result.injuriesHealed)
        : null;
    return Positioned(
      left: 0,
      right: 0,
      bottom: KlimmeckGuideTheme.spacingMd,
      child: IgnorePointer(
        child: Center(
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?_hpBar(drunk.result, max: max),
                if (healed != null)
                  Text(
                    healed,
                    key: PotionPourScene.healedKey,
                    textAlign: TextAlign.center,
                    style: lineStyle,
                  ),
                for (final lore in drunk.result.loreUnlocked)
                  Text(
                    loreUnlockedLine(lore),
                    key: PotionPourScene.loreKeyOf(lore.id),
                    textAlign: TextAlign.center,
                    style: lineStyle,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? _companionMaxOf(String petId) {
    for (final companion in widget.companions) {
      if (companion.petId == petId) return companion.maxLifePoints;
    }
    return null;
  }

  Widget? _hpBar(UseItemResult result, {required int? max}) {
    if (max == null || max <= 0) return null;
    final before = result.hpBefore.toDouble();
    final after = result.hpAfter.toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: before, end: after),
      duration: PotionPourScene.hpAnimationDuration,
      builder: (_, hp, _) => HpDeltaBar(
        key: PotionPourScene.hpKey,
        hp: hp,
        max: max,
        isGain: after > before,
        valueShadows: KlimmeckGuideTheme.bordersForText,
      ),
    );
  }
}
