import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:latlong2/latlong.dart';

/// Rotta del viaggio sotto i marker (07-CONTEXT D-04, D-06): tratteggiata
/// durante l'anteprima e fino all'arrivo di `activeTravel`; in viaggio il
/// tratto percorso è pieno in un tono, il rimanente tratteggiato in un altro.
/// Stile provvisorio (nessuna UI phase).
class TravelRouteLayer extends StatelessWidget {
  const TravelRouteLayer({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TravelProgressCubit, TravelProgressState>(
        builder: (context, progress) => BlocBuilder<TravelCubit, TravelState>(
          builder: (context, travel) {
            final polylines = travelRoutePolylines(
              progress: progress,
              travel: travel,
            );
            if (polylines.isEmpty) return const SizedBox.shrink();
            return PolylineLayer(polylines: polylines);
          },
        ),
      );
}

const double _travelledStrokeWidth = 4;
const double _remainingStrokeWidth = 3;
const int _minPolylinePoints = 2;
final StrokePattern _dashed = StrokePattern.dashed(segments: const [12, 8]);

/// Polilinee da disegnare: il viaggio vivo vince sull'anteprima. Un tratto con
/// meno di due punti non si disegna.
List<Polyline> travelRoutePolylines({
  required TravelProgressState progress,
  required TravelState travel,
}) {
  if (progress is TravelProgressActive && !progress.route.isEmpty) {
    return _liveRoute(progress);
  }
  final previewPoints = _previewPoints(travel);
  if (!_isDrawable(previewPoints)) return const [];
  return [_dashedRemaining(previewPoints!)];
}

List<Polyline> _liveRoute(TravelProgressActive progress) => [
  if (_isDrawable(progress.travelled))
    Polyline(
      points: progress.travelled,
      color: KlimmeckGuideTheme.royalCrimson,
      strokeWidth: _travelledStrokeWidth,
    ),
  if (_isDrawable(progress.remaining)) _dashedRemaining(progress.remaining),
];

Polyline _dashedRemaining(List<LatLng> points) => Polyline(
  points: points,
  color: KlimmeckGuideTheme.darkWood,
  strokeWidth: _remainingStrokeWidth,
  pattern: _dashed,
);

List<LatLng>? _previewPoints(TravelState travel) => switch (travel) {
  TravelConfirming(:final preview) ||
  TravelStarting(:final preview) ||
  TravelStarted(:final preview) => preview.road.points,
  TravelIdle() || TravelPreviewing() || TravelFailed() => null,
};

bool _isDrawable(List<LatLng>? points) =>
    points != null && points.length >= _minPolylinePoints;
