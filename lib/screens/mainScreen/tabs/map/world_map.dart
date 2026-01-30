import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../models/city.dart';
import '../../../../models/lore.dart';
import '../../../../models/quest/quest.dart';
import '../../../../shared/components/background_image.dart';
import '../../../../shared/components/modal/paper_sheet_modal.dart';
import '../../characterCubit/character_cubit.dart';
import 'components/city_modal.dart';
import 'cubit/world_map_cubit.dart';
import 'layers/character_marker_layer.dart';
import 'layers/city_markers_layer.dart';
import 'layers/quest_info_overlay.dart';
import 'layers/quest_markers_layer.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeBounds();
    _initializeAnimationControllers();
    _initializeMapOptions();
  }

  void _initializeBounds() {
    _bounds = LatLngBounds(LatLng(-90, -180), LatLng(90, 180));
  }

  void _initializeAnimationControllers() {
    _questAnimationController = AnimationController(
      vsync: this,
      duration: MapConstants.questSheetAnimationDuration,
    );

    _questAnimationController.addStatusListener((status) {
      if (status.isDismissed) {
        setState(() => _selectedQuest = null);
      }
    });
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
    );
  }

  @override
  void dispose() {
    _questAnimationController.dispose();
    _smoothTimer?.cancel();
    _zoomNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorldMapCubit, WorldMapState>(
      listener: (context, state) {
        if (state is WorldMapLoadData) {
          setState(() => _selectedLore = state.lore);
          _showCityInfoModal();
        }
      },
      child: BackgroundImage(
        child: GestureDetector(
          onTap: () => setState(() => _selectedQuest = null),
          child: FlutterMap(
            mapController: _mapController,
            options: _mapOptions,
            children: [
              _buildMapImage(),
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
              QuestInfoOverlay(
                animationController: _questAnimationController,
                selectedQuest: _selectedQuest,
              ),
            ],
          ),
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

  void _handleCharacterDragEnd(LatLng? finalLocation, City? targetCity) {
    _stopAnimation();

    if (targetCity != null && finalLocation != null) {
      context.read<CharacterCubit>().changeCharacterLocation(
            finalLocation,
            targetCity.markerLocation!.id,
          );
    }
  }

  void _selectQuest(Quest quest) {
    setState(() => _selectedQuest = quest);
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
