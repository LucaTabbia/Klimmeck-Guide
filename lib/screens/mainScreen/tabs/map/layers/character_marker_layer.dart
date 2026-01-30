import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../models/city.dart';
import '../../../../../shared/components/cached_svg.dart';
import '../../../characterCubit/character_cubit.dart';
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
  LatLng? _tmpLocation;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CharacterCubit, CharacterState>(
      listener: (context, state) {
        if (state is CharacterLoaded) {
          setState(() {
            _tmpLocation = state.character.status!.location!.location!;
          });
        }
      },
      builder: (context, state) {
        if (state is! CharacterLoaded) {
          return const SizedBox.shrink();
        }

        final characterLocation = state.character.status!.location!.location!;
        _tmpLocation ??= characterLocation;
        final displayLocation = _tmpLocation ?? characterLocation;
        final pawnPath = state.character.infos!.sex!.pawnPath;

        return MarkerLayer(
          markers: [
            Marker(
              point: displayLocation,
              child: ValueListenableBuilder<double>(
                valueListenable: widget.zoomNotifier,
                builder: (_, zoom, child) {
                  return Transform.scale(
                    scale: _calculateCharacterScale(zoom),
                    child: child!,
                  );
                },
                child: _buildDraggablePawn(pawnPath, state),
              ),
            ),
          ],
        );
      },
    );
  }

  double _calculateCharacterScale(double zoom) {
    return (zoom * 0.05 + 0.4) * 0.08 * MapConstants.characterMarkerSize;
  }

  Widget _buildDraggablePawn(String pawnPath, CharacterLoaded state) {
    return Draggable(
      feedback: SizedBox(
        width: MapConstants.characterMarkerSize,
        height: MapConstants.characterMarkerSize,
        child: CachedSvg(url: pawnPath),
      ),
      childWhenDragging: Opacity(
        opacity: 0,
        child: CachedSvg(url: pawnPath),
      ),
      onDragUpdate: (details) => _handleDragUpdate(details),
      onDragEnd: (details) => _handleDragEnd(),
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
        _tmpLocation = newLatLng;
      });

      widget.onDragUpdate(newLatLng);
    }
  }

  void _handleDragEnd() {
    if (_tmpLocation == null) {
      widget.onDragEnd(null, null);
      return;
    }

    final finalPosition = _tmpLocation!;

    // Check if inside a city area
    City? targetCity = MapUtils.findCityContainingPoint(finalPosition, widget.cities);

    // If not in any city area, find nearest city
    targetCity ??= MapUtils.findNearestCity(finalPosition, widget.cities);

    if (targetCity != null) {
      final newLocation = targetCity.markerLocation!.location!;
      setState(() {
        _tmpLocation = newLocation;
      });
      widget.onDragEnd(newLocation, targetCity);
    } else {
      // No city found, reset to original position
      setState(() {
        _tmpLocation = null;
      });
      widget.onDragEnd(null, null);
    }
  }
}

