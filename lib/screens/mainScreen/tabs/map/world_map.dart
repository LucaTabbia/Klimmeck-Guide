import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/city_marker.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/city_modal.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';
import 'package:latlong2/latlong.dart';

import '../../../../models/city.dart';
import '../../../../models/enums/city_size_type.dart';
import '../../../../models/lore.dart';
import '../../../../models/quest/quest.dart';
import '../../../../shared/components/popup/quest_info_sheet.dart';
import 'cubit/world_map_cubit.dart';

class WorldMap extends StatefulWidget {
  const WorldMap({super.key, required this.cities});

  final List<City> cities;

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> with TickerProviderStateMixin {
  LatLng? _lastTarget;
  double _velocityX = 0.0;
  double _velocityY = 0.0;
  Timer? _smoothTimer;
  final ValueNotifier<double> zoomNotifier = ValueNotifier(2);

  Lore? _selectedLore;
  Quest? _selectedQuest;
  LatLng? _tmpLocation;

  late AnimationController _animationController;
  late AnimationController _questAnimationController;

  late Animation<double> _positionAnimation;

  late Animation<LatLng> _latTween;

  late final MapOptions _mapOptions;
  late final LatLngBounds _bounds;

  final MapController _mapController = MapController();

  @override
  void initState() {
    _bounds = LatLngBounds(LatLng(-90, -180), LatLng(90, 180));

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );

    _questAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _positionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questAnimationController, curve: Curves.easeIn),
    );

    _questAnimationController.addStatusListener((status) {
      if (status.isDismissed) {
        setState(() {
          _selectedQuest = null;
        });
      }
    });

    _mapOptions = MapOptions(
      initialCenter: LatLng(0, 0),
      initialZoom: 2,
      crs: Epsg4326(),
      minZoom: 0,
      maxZoom: 5,
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
                    bounds: _bounds,
                    imageProvider: AssetImage('assets/images/worldMap.png'),
                  ),
                ],
              ),
              ValueListenableBuilder<double>(
                valueListenable: zoomNotifier,
                builder: (context, zoom, _) {
                  final visibleCities = widget.cities.where((city) {
                    switch (city.type?.cityClass) {
                      case CitySizeType.capital:
                        return zoom >= 0;
                      case CitySizeType.city:
                        return zoom >= 2.5;
                      case CitySizeType.village:
                        return zoom >= 3.2;
                      default:
                        return false;
                    }
                  }).toList();

                  return MarkerLayer(
                    markers: visibleCities.map((city) {
                      return Marker(
                        key: ValueKey(city.id),
                        point: city.markerLocation!.location!,
                        child: Transform.scale(
                          scale: (zoom * 0.2 + 0.1) * 0.08 * city.type!.size,
                          child: CityMarker(
                            city: city,
                            onTap: () => context
                                .read<WorldMapCubit>()
                                .loadLoreData(city.relatedLore!.id),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              BlocBuilder<QuestCubit, QuestState>(
                builder: (context, state) {
                  if (state is QuestLoaded) {
                    List<Quest> showableQuests = state.quests
                        .where(
                          (quest) =>
                              quest.infos?.markerLocation != null &&
                              !widget.cities.any(
                                (city) =>
                                    city.markerLocation ==
                                    quest.infos?.markerLocation,
                              ),
                        )
                        .toList();
                    return MarkerLayer(
                      markers: showableQuests
                          .map(
                            (quest) => Marker(
                              key: ValueKey(quest.id),
                              point: quest.infos!.markerLocation!.location!,
                              child: ValueListenableBuilder<double>(
                                valueListenable: zoomNotifier,
                                builder: (_, zoom, child) {
                                  if (zoom <= 4) {
                                    return const SizedBox.shrink();
                                  }
                                  return Transform.scale(
                                    scale: (zoom * 0.4 + 0.1),
                                    child: child!,
                                  );
                                },
                                child: GestureDetector(
                                  onTap: () => _selectQuest(quest),
                                  child: CachedSvg(
                                    url: quest.infos!.type!.imagePath,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }
                  return SizedBox();
                },
              ),
              BlocConsumer<CharacterCubit, CharacterState>(
                listener: (context, state) {
                  if (state is CharacterLoaded) {
                    setState(() {
                      _tmpLocation =
                          state.character.status!.location!.location!;
                    });
                  }
                },
                builder: (context, state) {
                  if (state is CharacterLoaded) {
                    final LatLng characterLocation =
                        state.character.status!.location!.location!;
                    _tmpLocation ??= characterLocation;

                    final LatLng displayLocation =
                        _tmpLocation ?? characterLocation;
                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: displayLocation,
                          child: ValueListenableBuilder<double>(
                            valueListenable: zoomNotifier,
                            builder: (_, zoom, child) {
                              return Transform.scale(
                                scale: (zoom * 0.05 + 0.4) * 0.08 * 60,
                                child: child!,
                              );
                            },
                            child: Draggable(
                              feedback: SizedBox(
                                width: 60,
                                height: 60,
                                child: CachedSvg(
                                  url: state.character.infos!.sex!.pawnPath,
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0,
                                child: CachedSvg(
                                  url: state.character.infos!.sex!.pawnPath,
                                ),
                              ),
                              onDragUpdate: (details) {
                                final renderObject = context.findRenderObject();
                                if (!mounted || renderObject == null) return;

                                if (renderObject is RenderBox &&
                                    renderObject.hasSize &&
                                    renderObject.attached) {
                                  final RenderBox mapRenderBox = renderObject;
                                  final Offset localOffsetOnMap = mapRenderBox
                                      .globalToLocal(details.globalPosition);

                                  final LatLng newLatLng = _mapController.camera
                                      .screenOffsetToLatLng(localOffsetOnMap);

                                  setState(() {
                                    _tmpLocation = newLatLng;
                                  });

                                  final Size screenSize = mapRenderBox.size;
                                  final Offset screenCenter = Offset(
                                    screenSize.width / 2,
                                    screenSize.height / 2,
                                  );

                                  final Offset dragOffset =
                                      localOffsetOnMap - screenCenter;
                                  final LatLng newCenter = _mapController.camera
                                      .screenOffsetToLatLng(
                                        screenCenter + dragOffset,
                                      );

                                  final LatLngBounds mapLimits = _bounds;

                                  final LatLng clampedCenter = LatLng(
                                    newCenter.latitude.clamp(
                                      mapLimits.south,
                                      mapLimits.north,
                                    ),
                                    newCenter.longitude.clamp(
                                      mapLimits.west,
                                      mapLimits.east,
                                    ),
                                  );

                                  _animateMapTo(clampedCenter);
                                }
                              },
                              onDragEnd: (details) {
                                _stopAnimation();

                                if (_tmpLocation == null) return;

                                LatLng finalPosition = _tmpLocation!;
                                City? targetCity;

                                // 1. Verifica se è all'interno di un'area cittadina
                                for (final city in widget.cities) {
                                  // City.area è List<List<double>> con [Lat, Lon]
                                  final area = city.area;
                                  if (area != null && area.isNotEmpty) {
                                    if (_pointInPolygon(
                                      finalPosition.latitude,
                                      finalPosition.longitude,
                                      city.area!,
                                    )) {
                                      targetCity = city;
                                      break;
                                    }
                                  }
                                }

                                targetCity ??= _findNearestCity(finalPosition);

                                if (targetCity != null) {
                                  final LatLng newLocation =
                                      targetCity.markerLocation!.location!;

                                  context
                                      .read<CharacterCubit>()
                                      .changeCharacterLocation(
                                        newLocation,
                                        targetCity.markerLocation!.id,
                                      );

                                  // Resetta la posizione temporanea
                                  setState(() {
                                    _tmpLocation = newLocation;
                                  });
                                } else {
                                  // Nessuna città trovata, annulla il drag e ritorna alla posizione originale
                                  setState(() {
                                    _tmpLocation = null;
                                  });
                                }
                              },
                              child: CachedSvg(
                                height: 60,
                                width: 60,
                                url: state.character.infos!.sex!.pawnPath,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return SizedBox();
                },
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
                        width:
                            MediaQuery.of(context).size.height *
                            1.5 *
                            (315 / 375),
                        child: _selectedQuest != null
                            ? SingleChildScrollView(
                                child: QuestInfoSheet(quest: _selectedQuest),
                              )
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

  bool _pointInPolygon(double lat, double lon, List<LatLng> polygon) {
    bool inside = false;

    List<List<double>> closedPolygon = List.from(polygon);
    if (closedPolygon.length > 1 &&
        (closedPolygon.first[0] != closedPolygon.last[0] ||
            closedPolygon.first[1] != closedPolygon.last[1])) {
      closedPolygon.add(closedPolygon.first);
    }

    // Nota: Il tuo formato Area è [[Lat, Lon]]. Usiamo Lat come Y, Lon come X.
    for (
      int i = 0, j = closedPolygon.length - 1;
      i < closedPolygon.length;
      j = i++
    ) {
      double yi = closedPolygon[i][0]; // Latitudine (Y)
      double xi = closedPolygon[i][1]; // Longitudine (X)
      double yj = closedPolygon[j][0];
      double xj = closedPolygon[j][1];

      bool intersect =
          ((yi > lat) != (yj > lat)) &&
          (lon <
              (xj - xi) *
                      (lat - yi) /
                      ((yj - yi).abs() < 1e-12 ? 1e-12 : (yj - yi)) +
                  xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  /// Trova la città più vicina al punto dato, misurando la distanza in LatLng.
  City? _findNearestCity(LatLng point) {
    City? nearestCity;
    double minDistanceSquared = double.infinity;

    for (final city in widget.cities) {
      final markerLocation = city.markerLocation?.location;
      if (markerLocation == null) continue;

      // Distanza al quadrato per evitare math.sqrt (più veloce)
      final distanceSquared =
          math.pow(markerLocation.latitude - point.latitude, 2) +
          math.pow(markerLocation.longitude - point.longitude, 2);

      if (distanceSquared < minDistanceSquared) {
        minDistanceSquared = distanceSquared.toDouble();
        nearestCity = city;
      }
    }
    return nearestCity;
  }

  // character_cubit.dart (file esterno)

  // ...
  // ...

  void _showModalCityInfo() {
    if (_selectedLore != null) {
      showModalBottomSheet(
        useSafeArea: false,
        isScrollControlled: true,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width,
        ),
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return PaperSheetModal(child: CityModal(lore: _selectedLore!));
        },
      );
    }
  }

  void _animateMapTo(LatLng target) {
    final LatLngBounds mapLimits = _bounds;

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

      const acceleration = 0.01;
      const damping = 0.8;

      _velocityX = (_velocityX + deltaLng * acceleration) * damping;
      _velocityY = (_velocityY + deltaLat * acceleration) * damping;

      final newLat = (current.latitude + _velocityY).clamp(
        mapLimits.south,
        mapLimits.north,
      );
      final newLng = (current.longitude + _velocityX).clamp(
        mapLimits.west,
        mapLimits.east,
      );

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
  LatLngTween({required LatLng begin, required LatLng end})
    : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}
