import 'package:flutter/widgets.dart';

/// Segnale di resistenza/rimbalzo per una magia: la `sequence` cambia a ogni esito (D-07, D-18).
typedef SpellResistSignal = ({String spellId, int sequence});

/// Trigger di [SpellResist] per [spellId]: la sequenza se il segnale la riguarda.
int? resistTriggerFor(SpellResistSignal? signal, String spellId) =>
    signal != null && signal.spellId == spellId ? signal.sequence : null;

/// Scuote orizzontalmente il figlio quando [trigger] cambia in un valore non nullo
/// nuovo (carta che resiste o torna al suo posto). Provvisorio (D-19).
class SpellResist extends StatefulWidget {
  const SpellResist({super.key, required this.trigger, required this.child});

  static const Duration duration = Duration(milliseconds: 300);
  static const double amplitude = 6;

  final int? trigger;
  final Widget child;

  @override
  State<SpellResist> createState() => _SpellResistState();
}

class _SpellResistState extends State<SpellResist>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SpellResist.duration,
  );

  late final Animation<double> _offset = TweenSequence<double>([
    _step(0, -SpellResist.amplitude),
    _step(-SpellResist.amplitude, SpellResist.amplitude),
    _step(SpellResist.amplitude, -SpellResist.amplitude * 2 / 3),
    _step(-SpellResist.amplitude * 2 / 3, SpellResist.amplitude * 2 / 3),
    _step(SpellResist.amplitude * 2 / 3, 0),
  ]).animate(_controller);

  static TweenSequenceItem<double> _step(double begin, double end) =>
      TweenSequenceItem(
        tween: Tween(begin: begin, end: end),
        weight: 1,
      );

  @override
  void didUpdateWidget(SpellResist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _offset,
    builder: (context, child) =>
        Transform.translate(offset: Offset(_offset.value, 0), child: child),
    child: widget.child,
  );
}
