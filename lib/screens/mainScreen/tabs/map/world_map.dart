import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../models/city.dart';
import '../../../../models/lore.dart';
import '../../../../models/quest/quest.dart';
import '../../../../models/travel/active_travel.dart';
import '../../../../models/travel/travel_destination.dart';
import '../../../../repository/services/time/server_clock_service.dart';
import '../../../../shared/components/background_image.dart';
import '../../../../shared/components/modal/paper_sheet_modal.dart';
import '../../characterCubit/character_cubit.dart';
import '../../travelCubit/travel_cubit.dart';
import 'components/city_modal.dart';
import 'components/travel_confirmation_sheet.dart';
import 'cubit/world_map_cubit.dart';
import 'layers/character_marker_layer.dart';
import 'layers/city_markers_layer.dart';
import 'layers/quest_info_overlay.dart';
import 'layers/quest_markers_layer.dart';
import 'layers/quest_paper_layer.dart';
import 'layers/travel_route_layer.dart';
import 'mapFocusCubit/map_focus_cubit.dart';
import 'travelProgressCubit/arrival_reread_ledger.dart';
import 'travelProgressCubit/travel_progress_cubit.dart';
import 'utils/map_constants.dart';
import 'utils/map_utils.dart';

class WorldMap extends StatefulWidget {
  const WorldMap({super.key, required this.cities});

  final List<City> cities;

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> with TickerProviderStateMixin {
  // Map state
  final MapController _mapController = MapController();
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(MapConstants.initialZoom);
  late final LatLngBounds _bounds;
  late final MapOptions _mapOptions;
  bool _isMapReady = false;

  // Travel state: vive con la mappa, ticchetta solo a mappa montata
  late final TravelProgressCubit _progressCubit;

  // Animation controllers
  late AnimationController _questAnimationController;

  // Smooth scrolling state
  Timer? _smoothTimer;
  LatLng? _lastTarget;
  double _velocityX = 0.0;
  double _velocityY = 0.0;

  // UI state
  Lore? _selectedLore;
  Quest? _selectedQuest;
  String? _selectedStateLabel;

  @override
  void initState() {
    super.initState();
    _initializeBounds();
    _initializeAnimationControllers();
    _initializeTravelProgress();
    _initializeMapOptions();
  }

  void _initializeTravelProgress() {
    _progressCubit = TravelProgressCubit(
      clock: context.read<ServerClockService>(),
      rereads: context.read<ArrivalRereadLedger>(),
    )..follow(_activeTravelOf(context.read<CharacterCubit>().state));
    // D-10: un arrivo già scaduto al montaggio non passa dal listener.
    _claimArrivalReread();
  }

  void _initializeBounds() {
    _bounds = LatLngBounds(LatLng(-90, -180), LatLng(90, 180));
  }

  void _initializeAnimationControllers() {
    _questAnimationController = AnimationController(
      vsync: this,
      duration: MapConstants.questSheetAnimationDuration,
    );

    _questAnimationController.addStatusListener(_onQuestAnimationStatusChanged);
  }

  void _initializeMapOptions() {
    _mapOptions = MapOptions(
      initialCenter: LatLng(0, 0),
      initialZoom: MapConstants.initialZoom,
      crs: Epsg4326(),
      minZoom: MapConstants.minZoom,
      maxZoom: MapConstants.maxZoom,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        rotationThreshold: 0,
      ),
      cameraConstraint: CameraConstraint.contain(bounds: _bounds),
      onTap: _handleMapTap,
      onPositionChanged: _handlePositionChanged,
      onMapReady: _handleMapReady,
    );
  }

  void _onQuestAnimationStatusChanged(AnimationStatus status) {
    if (status.isDismissed) {
      setState(() => _selectedQuest = null);
    }
  }

  @override
  void dispose() {
    _questAnimationController.removeStatusListener(_onQuestAnimationStatusChanged);
    _questAnimationController.dispose();
    _smoothTimer?.cancel();
    _zoomNotifier.dispose();
    _progressCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TravelProgressCubit>.value(
      value: _progressCubit,
      child: MultiBlocListener(listeners: _buildListeners(), child: _buildMap()),
    );
  }

  List<BlocListener> _buildListeners() {
    return [
      BlocListener<WorldMapCubit, WorldMapState>(
        listener: (context, state) {
          if (state is WorldMapLoadData) {
            setState(() => _selectedLore = state.lore);
            _showCityInfoModal();
          }
        },
      ),
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (previous, current) =>
            _activeTravelOf(previous) != _activeTravelOf(current),
        listener: (_, state) => _progressCubit.follow(_activeTravelOf(state)),
      ),
      // D-10: rilettura silenziosa, non logica di completamento.
      BlocListener<TravelProgressCubit, TravelProgressState>(
        bloc: _progressCubit,
        listenWhen: (previous, current) =>
            _refetchCountOf(current) > _refetchCountOf(previous),
        listener: (_, _) => _claimArrivalReread(),
      ),
      BlocListener<MapFocusCubit, MapFocusState>(
        listenWhen: (_, current) => current.isCharacterFocusPending,
        listener: (_, _) => _consumeCharacterFocus(),
      ),
      BlocListener<TravelCubit, TravelState>(
        listenWhen: (previous, current) =>
            previous is! TravelConfirming && current is TravelConfirming,
        listener: (_, state) => _fitPreviewRoute(state as TravelConfirming),
      ),
    ];
  }

  Widget _buildMap() {
    return BackgroundImage(
      child: GestureDetector(
        onTap: () => setState(() => _selectedQuest = null),
        child: FlutterMap(
          mapController: _mapController,
          options: _mapOptions,
          children: [
            _buildMapImage(),
            const TravelRouteLayer(),
            CityMarkersLayer(
              cities: widget.cities,
              zoomNotifier: _zoomNotifier,
            ),
            QuestMarkersLayer(
              cities: widget.cities,
              zoomNotifier: _zoomNotifier,
              onQuestSelected: _selectQuest,
            ),
            CharacterMarkerLayer(
              cities: widget.cities,
              zoomNotifier: _zoomNotifier,
              mapController: _mapController,
              bounds: _bounds,
              onDragUpdate: _handleCharacterDragUpdate,
              onDragEnd: _handleCharacterDragEnd,
            ),
            QuestPaperLayer(onOpen: _openFromPaper),
            QuestInfoOverlay(
              animationController: _questAnimationController,
              selectedQuest: _selectedQuest,
              stateLabel: _selectedStateLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapImage() {
    return OverlayImageLayer(
      overlayImages: [
        OverlayImage(
          bounds: _bounds,
          imageProvider: const AssetImage('assets/images/worldMap.png'),
        ),
      ],
    );
  }


  static ActiveTravel? _activeTravelOf(CharacterState state) =>
      state is CharacterLoaded ? state.character.status?.activeTravel : null;

  static int _refetchCountOf(TravelProgressState state) =>
      state is TravelProgressActive ? state.arrivalRefetchCount : 0;

  /// WR-02: il registro della sessione tiene il tetto delle riletture per viaggio.
  void _claimArrivalReread() {
    if (_progressCubit.claimArrivalReread()) {
      context.read<CharacterCubit>().refreshCharacter();
    }
  }

  /// D-09: con un viaggio in corso la camera inquadra la pedina una volta sola,
  /// quando la mappa è pronta (MapController inutilizzabile prima, Pitfall 8).
  void _handleMapReady() {
    _isMapReady = true;
    final pawn = _travellingPawnPoint();
    if (pawn != null) _mapController.move(pawn, _mapController.camera.zoom);
    _consumeCharacterFocus();
  }

  /// D-15: il tap su «Viaggio completato» centra la camera sulla pedina.
  void _consumeCharacterFocus() {
    if (!_isMapReady) return;
    if (!context.read<MapFocusCubit>().consumeCharacterFocus()) return;
    final pawn = _travellingPawnPoint() ?? _characterLocation();
    if (pawn != null) _mapController.move(pawn, _mapController.camera.zoom);
  }

  LatLng? _travellingPawnPoint() {
    final progress = _progressCubit.state;
    return progress is TravelProgressActive ? progress.position : null;
  }

  LatLng? _characterLocation() {
    final state = context.read<CharacterCubit>().state;
    return state is CharacterLoaded ? state.character.status?.location?.location : null;
  }

  void _handleMapTap(TapPosition pos, LatLng latLng) {
    if (_selectedQuest != null) {
      _questAnimationController.reverse();
    }
  }

  void _handlePositionChanged(MapCamera camera, bool hasGesture) {
    _zoomNotifier.value = camera.zoom;

    final clamped = MapUtils.clampToBounds(camera.center, _bounds);
    if (camera.center != clamped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(clamped, camera.zoom);
      });
    }
  }

  void _handleCharacterDragUpdate(LatLng newLocation) {
    final screenSize = (context.findRenderObject() as RenderBox?)?.size;
    if (screenSize == null) return;

    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
    final localOffset = _mapController.camera.latLngToScreenOffset(newLocation);
    final dragOffset = localOffset - screenCenter;
    final newCenter = _mapController.camera.screenOffsetToLatLng(screenCenter + dragOffset);
    final clampedCenter = MapUtils.clampToBounds(newCenter, _bounds);

    _animateMapTo(clampedCenter);
  }

  /// D-01/D-02: la città più vicina al rilascio è la meta; quella in cui il
  /// personaggio si trova già non apre nulla (la pedina torna al suo posto).
  void _handleCharacterDragEnd(LatLng? finalLocation, City? targetCity) {
    _stopAnimation();
    final character = context.read<CharacterCubit>().state;
    if (character is! CharacterLoaded) return;
    final destination = travelDestinationFor(
      target: targetCity,
      location: character.character.status?.location,
    );
    if (destination == null) return;
    final travelCubit = context.read<TravelCubit>();
    travelCubit.preview(characterId: character.character.id, destination: destination);
    _showTravelConfirmation(travelCubit, destination);
  }

  /// D-03/D-04: foglio di pergamena con la rotta visibile dietro (barriera
  /// trasparente); chiuderlo in qualsiasi modo annulla il flusso. Il foglio sta
  /// sul Navigator radice, fuori dai provider della shell (Pitfall 5).
  void _showTravelConfirmation(TravelCubit travelCubit, City destination) {
    showModalBottomSheet<void>(
      useSafeArea: false,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      context: context,
      builder: (_) => BlocProvider.value(
        value: travelCubit,
        child: NotificationListener<DraggableScrollableNotification>(
          onNotification: (_) => _isStartInFlight(travelCubit),
          child: PaperSheetModal(child: TravelConfirmationSheet(destination: destination)),
        ),
      ),
    ).whenComplete(travelCubit.cancel);
  }

  /// WR-01: trascinato al minimo il foglio chiude la rotta con `Navigator.pop`
  /// (salta il PopScope del foglio); con la partenza in volo la notifica si ferma qui.
  static bool _isStartInFlight(TravelCubit travelCubit) =>
      travelCubit.state is TravelStarting;

  /// D-04: la camera inquadra partenza e meta sopra il foglio (che occupa metà schermo).
  void _fitPreviewRoute(TravelConfirming state) {
    final points = state.preview.road.points;
    if (!_isMapReady || points.length < 2) return;
    final height = MediaQuery.of(context).size.height;
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: EdgeInsets.fromLTRB(
          MapConstants.previewRoutePadding,
          MapConstants.previewRoutePadding,
          MapConstants.previewRoutePadding,
          height * MapConstants.previewSheetHeightFraction + MapConstants.previewSheetGap,
        ),
        maxZoom: MapConstants.maxZoom,
      ),
    );
  }

  void _selectQuest(Quest quest) {
    setState(() {
      _selectedQuest = quest;
      _selectedStateLabel = null;
    });
    _questAnimationController.forward();
  }

  void _openFromPaper(Quest quest, String stateLabel) {
    setState(() {
      _selectedQuest = quest;
      _selectedStateLabel = stateLabel;
    });
    _questAnimationController.forward();
  }


  void _showCityInfoModal() {
    if (_selectedLore == null) return;

    showModalBottomSheet(
      useSafeArea: false,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => PaperSheetModal(child: CityModal(lore: _selectedLore!)),
    );
  }


  void _animateMapTo(LatLng target) {
    final clampedTarget = MapUtils.clampToBounds(target, _bounds);
    _lastTarget = clampedTarget;

    if (_smoothTimer?.isActive == true) return;

    _smoothTimer = Timer.periodic(MapConstants.smoothScrollInterval, (timer) {
      if (_lastTarget == null) {
        timer.cancel();
        return;
      }

      final current = _mapController.camera.center;
      final deltaLat = _lastTarget!.latitude - current.latitude;
      final deltaLng = _lastTarget!.longitude - current.longitude;
      final distance = math.sqrt(deltaLat * deltaLat + deltaLng * deltaLng);

      if (distance < MapConstants.animationStopThreshold) {
        timer.cancel();
        _smoothTimer = null;
        return;
      }

      _velocityX = (_velocityX + deltaLng * MapConstants.scrollAcceleration) *
          MapConstants.scrollDamping;
      _velocityY = (_velocityY + deltaLat * MapConstants.scrollAcceleration) *
          MapConstants.scrollDamping;

      final newLat = (current.latitude + _velocityY).clamp(_bounds.south, _bounds.north);
      final newLng = (current.longitude + _velocityX).clamp(_bounds.west, _bounds.east);

      _mapController.move(LatLng(newLat, newLng), _mapController.camera.zoom);
    });
  }

  void _stopAnimation() {
    _velocityX = 0.0;
    _velocityY = 0.0;
    _smoothTimer?.cancel();
    _smoothTimer = null;
  }
}
