import 'package:flutter/widgets.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';

/// Traduce il ciclo di vita dell'app negli eventi Flutter-free della sync
/// (Phase 3 D-13). Usa la coppia onPause/onRestart, l'unico vero passaggio
/// background<->foreground: il ritorno da inactive scatta anche per tendina notifiche e
/// dialog di sistema (Pitfall 3).
class AppLifecycleBridge extends StatefulWidget {
  const AppLifecycleBridge({super.key, required this.bus, required this.child});

  final AppLifecycleEventBus bus;
  final Widget child;

  @override
  State<AppLifecycleBridge> createState() => _AppLifecycleBridgeState();
}

class _AppLifecycleBridgeState extends State<AppLifecycleBridge> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onPause: widget.bus.notifyBackgrounded,
      onRestart: widget.bus.notifyForegrounded,
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
