import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/purse_tag.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/utils/pouch_flight.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

/// Borsello del personaggio sul bancone: il cartellino legato al laccio
/// dice quante monete contiene. Con un carrello da pagare ([onDelivered]),
/// trascinato fino al negoziante paga la transazione, rimpicciolendo man mano
/// che gli si avvicina; rilasciato prima torna nel suo angolo. Senza carrello
/// resta fermo.
class CoinsPouch extends StatefulWidget {
  const CoinsPouch({
    super.key,
    required this.width,
    required this.height,
    required this.shopkeeper,
    required this.purse,
    required this.onDelivered,
  });

  final double width;
  final double height;

  /// Punto dello schermo dove il negoziante prende la sacchetta.
  final Offset shopkeeper;

  /// Monete del personaggio, scritte sul cartellino.
  final Coins? purse;

  /// Pagamento del carrello; null quando non c'è nulla da pagare.
  final VoidCallback? onDelivered;

  static const Key flightKey = ValueKey('coins_pouch_flight');
  static const Key scaleKey = ValueKey('coins_pouch_scale');

  @override
  State<CoinsPouch> createState() => _CoinsPouchState();
}

class _CoinsPouchState extends State<CoinsPouch>
    with SingleTickerProviderStateMixin {
  static const Duration _returnDuration = Duration(milliseconds: 250);

  /// Spazio scrivibile del foglietto nel disegno della sacchetta: centro e
  /// misure in frazioni del lato, inclinazione in senso orario.
  static const Offset _tagCentre = Offset(0.167, 0.613);
  static const Size _tagInk = Size(0.13, 0.22);
  static const double _tagTilt = 0.45;

  late final AnimationController _return;

  Offset _displacement = Offset.zero;
  Offset _releasedAt = Offset.zero;
  PouchFlight? _flight;

  @override
  void initState() {
    super.initState();
    _return = AnimationController(vsync: this, duration: _returnDuration)
      ..addListener(_followReturn);
  }

  @override
  void dispose() {
    _return.dispose();
    super.dispose();
  }

  bool get _canPay => widget.onDelivered != null;

  @override
  Widget build(BuildContext context) {
    // Senza carrello il borsello non prende i tocchi: il suo riquadro copre
    // in parte lo zaino, che deve restare toccabile.
    return IgnorePointer(
      ignoring: !_canPay,
      child: Transform.translate(
        key: CoinsPouch.flightKey,
        offset: _displacement,
        child: GestureDetector(
          onPanStart: _canPay ? _onPanStart : null,
          onPanUpdate: _canPay ? _onPanUpdate : null,
          onPanEnd: _canPay ? (_) => _onPanEnd() : null,
          onPanCancel: _canPay ? _goBack : null,
          child: Transform.scale(
            key: CoinsPouch.scaleKey,
            scale: _flight?.scaleAt(_position) ?? 1,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                children: [
                  Semantics(
                    label: _canPay ? 'Paga il negoziante' : 'Il tuo borsello',
                    child: CachedSvg(
                      url: CloudinaryAssets.url(CloudinaryAssets.coinsPouch),
                      width: widget.width,
                      height: widget.height,
                    ),
                  ),
                  _buildTag(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag() {
    final side = widget.height;
    final ink = _tagInk * side;
    return Positioned(
      left: side * _tagCentre.dx - ink.width / 2,
      top: side * _tagCentre.dy - ink.height / 2,
      width: ink.width,
      height: ink.height,
      child: Transform.rotate(
        angle: _tagTilt,
        child: PurseTag(coins: widget.purse),
      ),
    );
  }

  Offset get _position => (_flight?.start ?? Offset.zero) + _displacement;

  void _onPanStart(DragStartDetails details) {
    _return.stop();
    final box = context.findRenderObject()! as RenderBox;
    setState(
      () => _flight = PouchFlight(
        start: box.localToGlobal(box.size.center(Offset.zero)),
        target: widget.shopkeeper,
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _displacement += details.delta);
  }

  void _onPanEnd() {
    if (_flight?.reachesShopkeeper(_position) ?? false) {
      widget.onDelivered?.call();
    }
    _goBack();
  }

  void _goBack() {
    _releasedAt = _displacement;
    _return.forward(from: 0);
  }

  void _followReturn() {
    final travelled = Curves.easeOut.transform(_return.value);
    setState(
      () => _displacement = Offset.lerp(_releasedAt, Offset.zero, travelled)!,
    );
  }
}
