import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/pencil_text.dart';
import 'package:klimmeck_guide/shared/components/written_ink.dart';

/// Contatore a matita degli usi/quantità, condiviso da carte magia e oggetti
/// (D-21). Un nuovo [value] prende subito il posto del vecchio e si scrive da
/// sinistra a destra, così anche con tocchi rapidi un numero resta in vista;
/// quando il valore se ne va, l'ultimo numero si cancella nello stesso verso.
/// Va tenuto montato anche senza valore.
class UsagesPencilCounter extends StatefulWidget {
  const UsagesPencilCounter({super.key, required this.value});

  static const Duration strokeDuration = Duration(milliseconds: 180);

  final int? value;

  @override
  State<UsagesPencilCounter> createState() => _UsagesPencilCounterState();
}

class _UsagesPencilCounterState extends State<UsagesPencilCounter>
    with SingleTickerProviderStateMixin {
  /// Margine dentro il ritaglio: la grafia a mano sporge oltre le cifre.
  static const EdgeInsets _inkMargin = EdgeInsets.symmetric(horizontal: 4);

  late final AnimationController _stroke;

  /// Numero sulla carta: resta anche mentre si cancella.
  int? _written;

  @override
  void initState() {
    super.initState();
    _written = widget.value;
    _stroke = AnimationController(
      vsync: this,
      duration: UsagesPencilCounter.strokeDuration,
      value: _written == null ? 0 : 1,
    );
  }

  @override
  void didUpdateWidget(UsagesPencilCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.value;
    if (value == oldWidget.value) return;
    if (value == null) {
      _stroke.reverse();
      return;
    }
    _written = value;
    _stroke.forward(from: 0);
  }

  @override
  void dispose() {
    _stroke.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final written = _written;
    return SizedBox(
      height: 50,
      width: 40,
      child: Center(
        child: written == null
            ? null
            : WrittenInk(
                stroke: _stroke,
                child: Padding(
                  padding: _inkMargin,
                  child: PencilText(
                    key: ValueKey<int>(written),
                    text: written.toString(),
                  ),
                ),
              ),
      ),
    );
  }
}
