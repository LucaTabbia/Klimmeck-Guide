import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../config/cloudinary_assets.dart';
import '../../../../../shared/components/cached_svg.dart';
import '../../../characterCubit/character_cubit.dart';
import '../travelProgressCubit/travel_progress_cubit.dart';
import '../utils/pawn_pointer.dart';

/// Freccia verso la propria pedina quando è fuori schermo (UAT 2026-11-14):
/// ruota verso di lei e resta vicino al bordo. Solo disegno, nessun gesto.
class PawnPointerLayer extends StatelessWidget {
  const PawnPointerLayer({super.key});

  static const Key arrowKey = ValueKey('map.pawnPointer');
  static const double arrowSize = 40;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return BlocBuilder<CharacterCubit, CharacterState>(
      builder: (context, character) =>
          BlocBuilder<TravelProgressCubit, TravelProgressState>(
            builder: (context, progress) {
              final point = _pawnPointOf(character, progress);
              if (point == null) return const SizedBox.shrink();
              final pointer = pawnPointerFor(
                viewport: camera.nonRotatedSize,
                pawn: camera.latLngToScreenOffset(point),
              );
              if (pointer == null) return const SizedBox.shrink();
              return _buildArrow(pointer);
            },
          ),
    );
  }

  /// In viaggio la pedina sta sul punto interpolato, da ferma sul suo luogo.
  static LatLng? _pawnPointOf(
    CharacterState character,
    TravelProgressState progress,
  ) {
    if (character is! CharacterLoaded) return null;
    final travelling = progress is TravelProgressActive
        ? progress.position
        : null;
    return travelling ?? character.character.status?.location?.location;
  }

  static Widget _buildArrow(PawnPointer pointer) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: pointer.position.dx - arrowSize / 2,
            top: pointer.position.dy - arrowSize / 2,
            child: Transform.rotate(
              key: arrowKey,
              angle: pointer.angle,
              child: CachedSvg(
                url: CloudinaryAssets.url(CloudinaryAssets.arrowDown),
                width: arrowSize,
                height: arrowSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
