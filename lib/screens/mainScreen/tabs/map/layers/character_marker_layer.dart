import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../models/city.dart';
import '../../../../../models/travel/travel_time_format.dart';
import '../../../../../shared/components/cached_svg.dart';
import '../../../../../theme/kg_theme.dart';
import '../../../characterCubit/character_cubit.dart';
import '../../../travelCubit/travel_cubit.dart';
import '../travelProgressCubit/travel_progress_cubit.dart';
import '../utils/map_constants.dart';
import '../utils/map_utils.dart';

class CharacterMarkerLayer extends StatefulWidget {
  const CharacterMarkerLayer({
    super.key,
    required this.cities,
    required this.zoomNotifier,
    required this.mapController,
    required this.bounds,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  static const Key pawnKey = ValueKey('map.pawn');
  static const Key travelLabelKey = ValueKey('map.travelLabel');
  static const Key awaitingAidLabelKey = ValueKey('map.awaitingAidLabel');

  /// Copy provvisoria (Phase 9 D-19): il ferito attende il soccorso (D-16).
  static const String awaitingAidLabel = 'In attesa di soccorso';

  final List<City> cities;
  final ValueNotifier<double> zoomNotifier;
  final MapController mapController;
  final LatLngBounds bounds;
  final void Function(LatLng newLocation) onDragUpdate;
  final void Function(LatLng? finalLocation, City? targetCity) onDragEnd;

  @override
  State<CharacterMarkerLayer> createState() => _CharacterMarkerLayerState();
}

class _CharacterMarkerLayerState extends State<CharacterMarkerLayer> {
  static const double _labelWidth = 160;
  static const double _labelHeight = 72;

  /// Punto sotto il dito, valorizzato solo durante il trascinamento.
  LatLng? _dragPoint;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharacterCubit, CharacterState>(
      builder: (context, characterState) {
        if (characterState is! CharacterLoaded) return const SizedBox.shrink();
        return BlocBuilder<TravelProgressCubit, TravelProgressState>(
          builder: (context, progress) => progress is TravelProgressActive
              ? _buildTravellingPawn(characterState, progress)
              : BlocBuilder<TravelCubit, TravelState>(
                  builder: (context, travel) =>
                      _buildIdlePawn(characterState, travel),
                ),
        );
      },
    );
  }

  Widget _buildIdlePawn(CharacterLoaded state, TravelState travel) {
    final location = state.character.status!.location!.location!;
    final point = _dragPoint ?? _confirmingDestination(travel) ?? location;
    final pawnPath = state.character.infos!.sex!.pawnPath;
    return MarkerLayer(
      markers: [
        Marker(
          point: point,
          child: _scaled(
            _buildDraggablePawn(
              pawnPath,
              canDrag: _canStartTravel(state, travel),
            ),
          ),
        ),
        if (state.character.status?.awaitingAid != null)
          Marker(
            point: point,
            width: _labelWidth,
            height: _labelHeight,
            alignment: Alignment.topCenter,
            child: const Align(
              alignment: Alignment.topCenter,
              child: _TravelLabel(
                key: CharacterMarkerLayer.awaitingAidLabelKey,
                text: CharacterMarkerLayer.awaitingAidLabel,
              ),
            ),
          ),
      ],
    );
  }

  /// D-08/D-13: in viaggio (libero o verso una quest) la pedina sta sul punto
  /// interpolato, senza trascinamento né tap; sopra fluttua solo il tempo
  /// rimanente, poi «In arrivo…» finché il BE non chiude il viaggio (D-10).
  Widget _buildTravellingPawn(
    CharacterLoaded state,
    TravelProgressActive progress,
  ) {
    final point =
        progress.position ?? state.character.status!.location!.location!;
    final pawnPath = state.character.infos!.sex!.pawnPath;
    return MarkerLayer(
      markers: [
        Marker(
          point: point,
          child: _scaled(_pawn(pawnPath)),
        ),
        Marker(
          point: point,
          width: _labelWidth,
          height: _labelHeight,
          alignment: Alignment.topCenter,
          child: Align(
            alignment: Alignment.topCenter,
            child: _TravelLabel(
              key: CharacterMarkerLayer.travelLabelKey,
              text: _labelOf(progress),
            ),
          ),
        ),
      ],
    );
  }

  static String _labelOf(TravelProgressActive progress) =>
      progress.isArriving
          ? travelArrivingLabel
          : formatGameDuration(progress.remainingTime);

  /// D-01: si trascina solo da fermi (nessun viaggio, nessuna missione standard,
  /// nessuna attesa di soccorso (Phase 9 D-16), nessuna conferma aperta).
  /// Pre-controllo: il BE resta giudice (D-14).
  static bool _canStartTravel(CharacterLoaded state, TravelState travel) =>
      state.character.status?.activeTravel == null &&
      state.character.quests?.pendingQuest == null &&
      state.character.status?.awaitingAid == null &&
      travel is TravelIdle;

  /// D-04: col foglio aperto la pedina sta sulla meta; altrimenti sulla
  /// posizione reale.
  static LatLng? _confirmingDestination(TravelState travel) => switch (travel) {
    TravelPreviewing(:final destination) ||
    TravelConfirming(:final destination) ||
    TravelStarting(:final destination) => destination.markerLocation?.location,
    _ => null,
  };

  Widget _scaled(Widget pawn) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.zoomNotifier,
      builder: (_, zoom, child) {
        return Transform.scale(
          scale: _calculateCharacterScale(zoom),
          child: child!,
        );
      },
      child: pawn,
    );
  }

  double _calculateCharacterScale(double zoom) {
    return (zoom * 0.05 + 0.4) * 0.08 * MapConstants.characterMarkerSize;
  }

  Widget _buildDraggablePawn(String pawnPath, {required bool canDrag}) {
    return Draggable(
      maxSimultaneousDrags: canDrag ? null : 0,
      feedback: SizedBox(
        width: MapConstants.characterMarkerSize,
        height: MapConstants.characterMarkerSize,
        child: CachedSvg(url: pawnPath),
      ),
      childWhenDragging: Opacity(
        opacity: 0,
        child: CachedSvg(url: pawnPath),
      ),
      onDragUpdate: _handleDragUpdate,
      onDragEnd: (_) => _handleDragEnd(),
      child: _pawn(pawnPath),
    );
  }

  static Widget _pawn(String pawnPath) {
    return KeyedSubtree(
      key: CharacterMarkerLayer.pawnKey,
      child: CachedSvg(
        height: MapConstants.characterMarkerSize,
        width: MapConstants.characterMarkerSize,
        url: pawnPath,
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final renderObject = context.findRenderObject();
    if (!mounted || renderObject == null) return;

    if (renderObject is RenderBox && renderObject.hasSize && renderObject.attached) {
      final localOffset = renderObject.globalToLocal(details.globalPosition);
      final newLatLng = widget.mapController.camera.screenOffsetToLatLng(localOffset);

      setState(() {
        _dragPoint = newLatLng;
      });

      widget.onDragUpdate(newLatLng);
    }
  }

  /// Regola D-01: città che contiene il punto, altrimenti la più vicina.
  void _handleDragEnd() {
    final releasePoint = _dragPoint;
    setState(() => _dragPoint = null);
    if (releasePoint == null) {
      widget.onDragEnd(null, null);
      return;
    }

    final targetCity =
        MapUtils.findCityContainingPoint(releasePoint, widget.cities) ??
        MapUtils.findNearestCity(releasePoint, widget.cities);
    widget.onDragEnd(targetCity?.markerLocation?.location, targetCity);
  }
}

/// Etichetta di viaggio: solo testo, non intercetta i gesti della mappa.
class _TravelLabel extends StatelessWidget {
  const _TravelLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KlimmeckGuideTheme.parchment,
          borderRadius: BorderRadius.circular(KlimmeckGuideTheme.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KlimmeckGuideTheme.spacingSm,
            vertical: KlimmeckGuideTheme.spacingXs,
          ),
          child: AutoSizeText(
            text,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: KlimmeckGuideTheme.darkWood,
            ),
          ),
        ),
      ),
    );
  }
}
