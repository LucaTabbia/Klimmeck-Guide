import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/city_marker.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/city_modal.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';
import 'package:latlong2/latlong.dart';

import '../../../../models/city.dart';
import '../../../../models/lore.dart';
import '../../../../models/quest/quest.dart';
import '../../../../shared/components/popup/quest_info_sheet.dart';
import 'cubit/world_map_cubit.dart';

class WorldMap extends StatefulWidget {
  const WorldMap({super.key, required this.character, required this.cities, required this.quests});

  final Character character;
  final List<City> cities;
  final List<Quest> quests;

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> with TickerProviderStateMixin {
  LatLng? _lastTarget;
  double _velocityX = 0.0;
  double _velocityY = 0.0;
  Timer? _smoothTimer;
  final ValueNotifier<double> zoomNotifier = ValueNotifier(3.06);

  Lore? _selectedLore;
  Quest? _selectedQuest;
  List<Quest> _showableQuests = [];

  late AnimationController _animationController;
  late AnimationController _questAnimationController;

  late Animation<double> _positionAnimation;

  late Animation<LatLng> _latTween;

  late final MapOptions _mapOptions;
  final _bounds = LatLngBounds(LatLng(0, 0), LatLng(79.9, 180));

  final MapController _mapController = MapController();

  @override
  void initState() {
    _showableQuests = widget.quests
        .where(
          (quest) =>
              quest.infos?.markerLocation != null &&
              !widget.cities.any((city) => city.markerLocation == quest.infos?.markerLocation),
        )
        .toList();

    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 100));

    _questAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _questAnimationController, curve: Curves.easeIn));

    _questAnimationController.addStatusListener((status) {
      if (status.isDismissed) {
        setState(() {
          _selectedQuest = null;
        });
      }
    });

    _mapOptions = MapOptions(
      initialCenter: LatLng(55, 90),
      initialZoom: 3.06,
      minZoom: 2.3,
      maxZoom: 6.0,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        rotationThreshold: 0,
      ),
      cameraConstraint: CameraConstraint.contain(bounds: _bounds),
      onTap: (pos, latLng) {
        if (_selectedQuest != null) {
          setState(() {
            _selectedQuest = null;
          });
        }
      },
      onPositionChanged: (camera, hasGesture) {
        zoomNotifier.value = camera.zoom;
        final clamped = LatLng(
          camera.center.latitude.clamp(_bounds.south, _bounds.north),
          camera.center.longitude.clamp(_bounds.west, _bounds.east),
        );
        if (camera.center != clamped) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(clamped, camera.zoom);
          });
        }
      },
    );

    _animationController.addListener(() {
      final LatLng current = _latTween.value;
      _mapController.move(current, _mapController.camera.zoom);
    });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorldMapCubit, WorldMapState>(
      listener: (context, state) {
        if (state is WorldMapLoadData) {
          setState(() {
            _selectedLore = state.lore;
          });
          _showModalCityInfo();
        }
      },
      child: BackgroundImage(
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedQuest = null;
          }),
          child: FlutterMap(
            mapController: _mapController,
            options: _mapOptions,
            children: [
              OverlayImageLayer(
                overlayImages: [
                  OverlayImage(
                    bounds: LatLngBounds(LatLng(0, 0), LatLng(80, 180)),
                    imageProvider: AssetImage('assets/images/worldMap.png'),
                  ),
                ],
              ),
              MarkerLayer(
                markers: widget.cities
                    .map(
                      (city) => Marker(
                        key: ValueKey(city.id),
                        point: city.markerLocation!,
                        child: ValueListenableBuilder<double>(
                          valueListenable: zoomNotifier,
                          builder: (_, zoom, child) {
                            return Transform.scale(scale: zoom * 0.8, child: child);
                          },
                          child: CityMarker(
                            city: city,
                            onTap: () =>
                                context.read<WorldMapCubit>().loadLoreData(city.relatedLore!.id),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              MarkerLayer(
                markers: _showableQuests
                    .map(
                      (quest) => Marker(
                        key: ValueKey(quest.id),
                        point: quest.infos!.markerLocation!,
                        child: ValueListenableBuilder<double>(
                          valueListenable: zoomNotifier,
                          builder: (_, zoom, child) {
                            if (zoom <= 4) {
                              return const SizedBox.shrink();
                            }
                            return Transform.scale(scale: zoom * 0.4, child: child!);
                          },
                          child: GestureDetector(
                            onTap: () => _selectQuest(quest),
                            child: CachedSvg(url: quest.infos!.type!.imagePath),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.character.status!.location!,
                    width: 60,
                    height: 60,
                    child: Draggable(
                      feedback: SizedBox(
                        width: 40,
                        height: 40,
                        child: CachedSvg(url: widget.character.infos!.sex!.pawnPath),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0,
                        child: CachedSvg(url: widget.character.infos!.sex!.pawnPath),
                      ),
                      onDragUpdate: (details) {
                        final renderObject = context.findRenderObject();
                        if (!mounted || renderObject == null) return;

                        if (renderObject is RenderBox &&
                            renderObject.hasSize &&
                            renderObject.attached) {
                          final RenderBox mapRenderBox = renderObject;
                          final Offset localOffsetOnMap = mapRenderBox.globalToLocal(
                            details.globalPosition,
                          );

                          final LatLng newLatLng = _mapController.camera.screenOffsetToLatLng(
                            localOffsetOnMap,
                          );

                          setState(() {
                            widget.character.status?.location = newLatLng;
                          });

                          final Size screenSize = mapRenderBox.size;
                          final Offset screenCenter = Offset(
                            screenSize.width / 2,
                            screenSize.height / 2,
                          );

                          final Offset dragOffset = localOffsetOnMap - screenCenter;
                          final LatLng newCenter = _mapController.camera.screenOffsetToLatLng(
                            screenCenter + dragOffset,
                          );

                          final LatLngBounds mapLimits = LatLngBounds(
                            LatLng(0, 0),
                            LatLng(80, 180),
                          );

                          final LatLng clampedCenter = LatLng(
                            newCenter.latitude.clamp(mapLimits.south, mapLimits.north),
                            newCenter.longitude.clamp(mapLimits.west, mapLimits.east),
                          );

                          _animateMapTo(clampedCenter);
                        }
                      },
                      onDragEnd: (details) {
                        _stopAnimation();
                      },
                      child: CachedSvg(url: widget.character.infos!.sex!.pawnPath),
                    ),
                  ),
                ],
              ),
              AnimatedBuilder(
                animation: _questAnimationController,
                builder: (context, child) {
                  return Positioned(
                    top: _positionAnimation.value,
                    right: 0,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.height * 1.5 * (315 / 375),
                        child: _selectedQuest != null
                            ? SingleChildScrollView(child: QuestInfoSheet(quest: _selectedQuest))
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModalCityInfo() {
    if (_selectedLore != null) {
      showModalBottomSheet(
        useSafeArea: false,
        isScrollControlled: true,
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return PaperSheetModal(child: CityModal(lore: _selectedLore!));
        },
      );
    }
  }

  void _animateMapTo(LatLng target) {
    final LatLngBounds mapLimits = LatLngBounds(LatLng(0, 0), LatLng(79.9, 180));

    final clampedTarget = LatLng(
      target.latitude.clamp(mapLimits.south, mapLimits.north),
      target.longitude.clamp(mapLimits.west, mapLimits.east),
    );

    _lastTarget = clampedTarget;

    if (_smoothTimer?.isActive == true) return;

    _smoothTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (_lastTarget == null) {
        timer.cancel();
        return;
      }

      final current = _mapController.camera.center;
      final targetLat = _lastTarget!.latitude;
      final targetLng = _lastTarget!.longitude;

      final deltaLat = targetLat - current.latitude;
      final deltaLng = targetLng - current.longitude;
      final distance = math.sqrt(deltaLat * deltaLat + deltaLng * deltaLng);

      if (distance < 0.001) {
        timer.cancel();
        _smoothTimer = null;
        return;
      }

      const acceleration = 0.02;
      const damping = 0.8;

      _velocityX = (_velocityX + deltaLng * acceleration) * damping;
      _velocityY = (_velocityY + deltaLat * acceleration) * damping;

      final newLat = (current.latitude + _velocityY).clamp(mapLimits.south, mapLimits.north);
      final newLng = (current.longitude + _velocityX).clamp(mapLimits.west, mapLimits.east);

      _mapController.move(LatLng(newLat, newLng), _mapController.camera.zoom);
    });
  }

  void _stopAnimation() {
    _velocityX = 0.0;
    _velocityY = 0.0;

    _smoothTimer?.cancel();
    _smoothTimer = null;
  }

  void _selectQuest(Quest quest) {
    setState(() {
      _selectedQuest = quest;
    });
    _questAnimationController.forward();
  }
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}
