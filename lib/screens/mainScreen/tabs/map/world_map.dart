import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:klimmeck_guide/models/character.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/city_marker.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/city_modal.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart';
import 'package:latlong2/latlong.dart';

import '../../../../models/city.dart';
import '../../../../models/lore.dart';
import 'components/city_card.dart';

class WorldMap extends StatefulWidget {
  const WorldMap({super.key, required this.character, required this.cities});

  final Character character;
  final List<City> cities;

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> with SingleTickerProviderStateMixin {
  LatLng? lastTarget;
  double velocityX = 0.0;
  double velocityY = 0.0;
  Timer? smoothTimer;
  double currentZoom = 3.06;

  City? selectedCity;
  Lore? selectedLore;

  late AnimationController animationController;
  late Animation<LatLng> latTween;
  late LatLng animationStart;
  late LatLng animationEnd;

  bool adminMode = true;
  final MapController mapController = MapController();

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 100));

    animationController.addListener(() {
      final LatLng current = latTween.value;
      mapController.move(current, mapController.camera.zoom);
    });
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorldMapCubit, WorldMapState>(
      listener: (context, state) {
        if (state is WorldMapLoadData) {
          setState(() {
            selectedLore = state.lore;
          });
          showModalCityInfo();
        }
      },
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          onPositionChanged: (camera, hasGesture) {
            setState(() {
              currentZoom = camera.zoom;
            });
          },
          onTap: (tapPosition, latLong) {
            if (selectedCity != null) {
              setState(() {
                selectedCity = null;
              });
            }
          },
          initialCenter: LatLng(55, 90),
          initialZoom: 3.06,
          minZoom: 2.3,
          maxZoom: 6.0,
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            rotationThreshold: 0,
          ),
          cameraConstraint: CameraConstraint.contain(
            bounds: LatLngBounds(LatLng(0, 0), LatLng(79.9, 180)),
          ),
        ),
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
                    point: city.markerLocation!,
                    height: 200,
                    width: 200,
                    child: CityMarker(
                      city: city,
                      zoom: currentZoom,
                      onTap: () => setState(() {
                        selectedCity = city;
                      }),
                    ),
                  ),
                )
                .toList(),
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: widget.character.location!,
                width: 60,
                height: 60,
                child: Draggable(
                  feedback: Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
                  childWhenDragging: Opacity(
                    opacity: 0,
                    child: Icon(Icons.person_pin_circle, size: 40),
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

                      final LatLng newLatLng = mapController.camera.screenOffsetToLatLng(
                        localOffsetOnMap,
                      );

                      setState(() {
                        widget.character.location = newLatLng;
                      });

                      final Size screenSize = mapRenderBox.size;
                      final Offset screenCenter = Offset(
                        screenSize.width / 2,
                        screenSize.height / 2,
                      );

                      final Offset dragOffset = localOffsetOnMap - screenCenter;
                      final LatLng newCenter = mapController.camera.screenOffsetToLatLng(
                        screenCenter + dragOffset,
                      );

                      final LatLngBounds mapLimits = LatLngBounds(LatLng(0, 0), LatLng(80, 180));

                      final LatLng clampedCenter = LatLng(
                        newCenter.latitude.clamp(mapLimits.south, mapLimits.north),
                        newCenter.longitude.clamp(mapLimits.west, mapLimits.east),
                      );

                      animateMapTo(clampedCenter);
                    }
                  },
                  onDragEnd: (details) {
                    stopAnimation();
                  },
                  child: Icon(
                    Icons.person_pin_circle,
                    color: adminMode ? Colors.red : Colors.green,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
          if (selectedCity != null) getSelectedCityCard(),
        ],
      ),
    );
  }

  void showModalCityInfo() {
    if (selectedCity != null && selectedLore != null) {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return CityModal(city: selectedCity!, lore: selectedLore!);
        },
      );
    }
  }

  Positioned getSelectedCityCard() {
    Offset startOffset = mapController.camera
        .latLngToScreenOffset(selectedCity!.markerLocation!)
        .translate(-100.0, -155.0);

    if (startOffset.dy <= 40) {
      startOffset = startOffset.translate(0.0, 190.0);
    }
    return Positioned(
      left: startOffset.dx,
      top: startOffset.dy,
      child: CityCard(
        city: selectedCity!,
        onTap: () => context.read<WorldMapCubit>().loadLoreData(selectedCity!.relatedLore!.id),
      ),
    );
  }

  void animateMapTo(LatLng target) {
    lastTarget = target;

    if (smoothTimer?.isActive == true) return;

    smoothTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (lastTarget == null) {
        timer.cancel();
        return;
      }

      final current = mapController.camera.center;
      final targetLat = lastTarget!.latitude;
      final targetLng = lastTarget!.longitude;

      final deltaLat = targetLat - current.latitude;
      final deltaLng = targetLng - current.longitude;
      final distance = math.sqrt(deltaLat * deltaLat + deltaLng * deltaLng);

      if (distance < 0.001) {
        timer.cancel();
        smoothTimer = null;
        return;
      }

      const acceleration = 0.02;
      const damping = 0.8;

      velocityX = (velocityX + deltaLng * acceleration) * damping;
      velocityY = (velocityY + deltaLat * acceleration) * damping;

      final newLat = current.latitude + velocityY;
      final newLng = current.longitude + velocityX;

      mapController.move(LatLng(newLat, newLng), mapController.camera.zoom);
    });
  }

  void stopAnimation() {
    velocityX = 0.0;
    velocityY = 0.0;

    smoothTimer?.cancel();
    smoothTimer = null;
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
