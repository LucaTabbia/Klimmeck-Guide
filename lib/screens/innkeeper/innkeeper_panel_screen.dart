import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/request_card_view.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_access.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_route.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Pannello della Locanda (10-CONTEXT D-01/D-05..D-09): utility screen con la
/// coda viva del GM; il loader solo fino al primo snapshot (apertura
/// esplicita). Si chiude da solo su `FORBIDDEN` o sul ruolo perso (D-04).
/// Richiede [PendingRequestsCubit] e [AuthCubit] sopra di sé.
class InnkeeperPanelScreen extends StatelessWidget {
  const InnkeeperPanelScreen({super.key});

  static const String title = 'Locanda';
  static const String emptyTitle = 'Nessuna richiesta in attesa';
  static const String emptyNote = 'La coda si aggiorna da sola';
  static const String unavailableMessage = 'La Locanda non è disponibile';

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PendingRequestsCubit, PendingRequestsState>(
          listenWhen: (previous, current) =>
              !previous.isForbidden && current.isForbidden,
          listener: _closeForbidden,
        ),
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              isInnkeeperSession(previous) && !isInnkeeperSession(current),
          listener: (context, _) => closeInnkeeperPanel(context),
        ),
      ],
      child: _buildScaffold(),
    );
  }

  // default per veto (10-CONTEXT D-04/C8): SnackBar invece del pop silenzioso
  void _closeForbidden(BuildContext context, PendingRequestsState _) {
    final messenger = ScaffoldMessenger.of(context);
    closeInnkeeperPanel(context);
    messenger.showSnackBar(const SnackBar(content: Text(unavailableMessage)));
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: DecoratedBox(
        decoration: KlimmeckGuideTheme.getParchmentBackground(),
        child: SafeArea(
          child: BlocBuilder<PendingRequestsCubit, PendingRequestsState>(
            builder: _buildQueue,
          ),
        ),
      ),
    );
  }

  Widget _buildQueue(BuildContext context, PendingRequestsState state) {
    if (!state.isLoaded) return const Center(child: KGLoader());
    final cards = state.cards;
    if (cards.isEmpty) return const _EmptyQueue();
    return ListView.separated(
      padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingLg),
      itemCount: cards.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: KlimmeckGuideTheme.spacingMd),
      itemBuilder: (_, index) => RequestCardView(
        key: RequestCardView.keyFor(cards[index].questId),
        card: cards[index],
        serverNow: state.serverNow,
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(InnkeeperPanelScreen.emptyTitle, style: theme.titleMedium),
          const SizedBox(height: KlimmeckGuideTheme.spacingSm),
          Text(InnkeeperPanelScreen.emptyNote, style: theme.bodyMedium),
        ],
      ),
    );
  }
}
