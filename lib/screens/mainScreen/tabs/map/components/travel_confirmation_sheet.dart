import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/travel/travel_time_format.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

typedef _TravelNumbers = ({String distance, String duration, String arrival});

/// Conferma del viaggio su pergamena (07-CONTEXT D-03): meta subito, poi
/// distanza, durata ed ETA del BE (ETA = ora server stimata + durata, C4).
/// "Parti" è l'unica via a `startTravel`; "Resta" annulla. Si chiude da sé
/// all'avvio o a un rifiuto (il banner lo pubblica TravelOutcomeListener).
/// Nessun costo (BE Phase 8). Stile provvisorio (nessuna UI phase).
class TravelConfirmationSheet extends StatefulWidget {
  const TravelConfirmationSheet({super.key, required this.destination});

  final City destination;

  static const Key departKey = ValueKey('travel.depart');
  static const Key stayKey = ValueKey('travel.stay');
  static const String pendingValue = '…';

  @override
  State<TravelConfirmationSheet> createState() =>
      _TravelConfirmationSheetState();
}

class _TravelConfirmationSheetState extends State<TravelConfirmationSheet> {
  static const double _imageSize = 120;
  static const Size _minTapTarget = Size(44, 44);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _closeIfAlreadySettled(),
    );
  }

  /// Un rifiuto dell'anteprima già gestito (e resettato) prima del primo frame
  /// non arriva al BlocListener: il foglio si chiude da sé invece di restare
  /// sui segnaposto.
  void _closeIfAlreadySettled() {
    if (!mounted) return;
    final state = context.read<TravelCubit>().state;
    if (state is TravelIdle || state is TravelFailed) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<TravelCubit, TravelState>(
    listenWhen: (_, current) =>
        current is TravelStarted || current is TravelFailed,
    listener: (context, _) => Navigator.of(context).maybePop(),
    child: BlocBuilder<TravelCubit, TravelState>(
      builder: (context, state) => _content(context, state),
    ),
  );

  Widget _content(BuildContext context, TravelState state) {
    final image = widget.destination.relatedLore?.image;
    final numbers = _numbersOf(state);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: KlimmeckGuideTheme.spacingLg),
        AutoSizeText(
          widget.destination.name ?? '',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (image != null)
          CachedSvg(url: image, width: _imageSize, height: _imageSize),
        const SizedBox(height: KlimmeckGuideTheme.spacingMd),
        _numberRow(context, 'Distanza', numbers?.distance),
        _numberRow(context, 'Durata', numbers?.duration),
        _numberRow(context, 'Arrivo', numbers?.arrival),
        const SizedBox(height: KlimmeckGuideTheme.spacingMd),
        _actions(context, state),
      ],
    );
  }

  _TravelNumbers? _numbersOf(TravelState state) => switch (state) {
    TravelConfirming(:final preview, :final eta, :final previewedAt) ||
    TravelStarting(:final preview, :final eta, :final previewedAt) => (
      distance: formatTravelDistance(preview.distance),
      duration: formatTravelDuration(
        Duration(milliseconds: preview.duration.round()),
      ),
      arrival: formatArrival(eta, serverNow: previewedAt),
    ),
    _ => null,
  };

  Widget _numberRow(BuildContext context, String label, String? value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: KlimmeckGuideTheme.spacingXs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium),
          Flexible(
            child: AutoSizeText(
              value ?? TravelConfirmationSheet.pendingValue,
              maxLines: 1,
              textAlign: TextAlign.end,
              style: value == null
                  ? textTheme.bodyMedium?.copyWith(
                      color: KlimmeckGuideTheme.darkBronze,
                    )
                  : textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, TravelState state) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _action(
        key: TravelConfirmationSheet.stayKey,
        label: 'Resta',
        onPressed: () {
          context.read<TravelCubit>().cancel();
          Navigator.of(context).maybePop();
        },
      ),
      _action(
        key: TravelConfirmationSheet.departKey,
        label: 'Parti',
        onPressed: state is TravelConfirming
            ? () => context.read<TravelCubit>().start()
            : null,
      ),
    ],
  );

  Widget _action({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
  }) => Semantics(
    label: label,
    button: true,
    child: TextButton(
      key: key,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: _minTapTarget,
        foregroundColor: KlimmeckGuideTheme.darkWood,
      ),
      child: Text(label),
    ),
  );
}
