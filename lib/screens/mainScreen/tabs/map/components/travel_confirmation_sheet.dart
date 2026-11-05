import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/travel/travel_cost_text.dart';
import 'package:klimmeck_guide/models/travel/travel_time_format.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';

typedef _TravelNumbers = ({
  String distance,
  String duration,
  String? arrival,
  String food,
  String life,
  bool isStarving,
});

/// Conferma del viaggio su pergamena (07-CONTEXT D-03): meta subito, poi
/// distanza, durata, ETA, cibo e vita persa del BE (ETA = ora server stimata
/// + durata, C4; cibo e vita, 15-CONTEXT D-02). "Parti" è l'unica via a
/// `startTravel` ed è spento se il BE dice che il personaggio non arriverebbe
/// vivo; "Resta" annulla. Mentre la partenza è in volo né "Resta" né
/// indietro/barriera chiudono il foglio: si chiude da sé all'avvio o a un
/// rifiuto; a un rifiuto per fame resta aperto sull'ultima anteprima finché
/// il cubit la rinnova (D-03). Stile provvisorio (nessuna UI phase).
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
  static const int _foodMaxLines = 3;
  static const int _lifeMaxLines = 2;

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
    listener: (context, _) => _closeSettled(context),
    child: BlocBuilder<TravelCubit, TravelState>(
      builder: (context, state) => PopScope(
        canPop: state is! TravelStarting,
        child: _content(context, state),
      ),
    ),
  );

  /// `pop` e non `maybePop`: il PopScope ricostruito dopo il listener blocca
  /// ancora l'uscita da `TravelStarting`.
  void _closeSettled(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context).pop();
  }

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
        _numberRow(context, 'Cibo', numbers?.food, maxLines: _foodMaxLines),
        _numberRow(
          context,
          'Vita',
          numbers?.life,
          maxLines: _lifeMaxLines,
          valueColor: numbers?.isStarving == true
              ? KlimmeckGuideTheme.bloodRed
              : null,
        ),
        const SizedBox(height: KlimmeckGuideTheme.spacingMd),
        _actions(context, state),
      ],
    );
  }

  _TravelNumbers? _numbersOf(TravelState state) => switch (state) {
    TravelQuote(:final preview, :final eta, :final previewedAt) => (
      distance: formatTravelDistance(preview.distance),
      duration: formatGameDuration(
        Duration(milliseconds: preview.duration.round()),
      ),
      arrival: _arrivalOf(eta, previewedAt),
      food: foodText(preview.food, empty: noFoodSheetText),
      life: lifeText(preview),
      isStarving: !preview.arrivesAlive,
    ),
    _ => null,
  };

  /// ETA nullo finché l'orologio non è sincronizzato: resta il segnaposto.
  static String? _arrivalOf(DateTime? eta, DateTime? previewedAt) =>
      eta == null || previewedAt == null
      ? null
      : formatArrival(eta, serverNow: previewedAt);

  Widget _numberRow(
    BuildContext context,
    String label,
    String? value, {
    int maxLines = 1,
    Color? valueColor,
  }) {
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
              maxLines: maxLines,
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(
                color: value == null
                    ? KlimmeckGuideTheme.darkBronze
                    : valueColor,
              ),
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
        onPressed: state is TravelStarting
            ? null
            : () {
                context.read<TravelCubit>().cancel();
                Navigator.of(context).maybePop();
              },
      ),
      _action(
        key: TravelConfirmationSheet.departKey,
        label: 'Parti',
        onPressed: state is TravelConfirming && state.preview.arrivesAlive
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
