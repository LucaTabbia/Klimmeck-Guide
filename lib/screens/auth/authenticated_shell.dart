import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/storage/cubit/storage_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/main_screen.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/cubit/library_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';
import 'package:klimmeck_guide/screens/splash/cubit/splash_cubit.dart';
import 'package:klimmeck_guide/screens/splash/splash_screen.dart';

/// Sessione autenticata: monta i Cubit gameplay, avvia il preload SVG
/// Cloudinary (REST autenticata, quindi solo ora) ed entra nel MainScreen.
///
/// I Cubit gameplay vivono qui e si chiudono quando `AuthGate` rimuove la
/// shell (logout/cambio account); usano `SafeEmit`, quindi una risposta
/// ancora in volo alla chiusura viene ignorata.
///
/// `showDialog`/`showModalBottomSheet`/`Navigator.push` montano route sul
/// Navigator radice, FUORI da questi provider: passare i Cubit con
/// `BlocProvider.value` o leggerli prima di aprire la route.
class AuthenticatedShell extends StatelessWidget {
  const AuthenticatedShell({
    super.key,
    required this.graphQl,
    this.mainScreenBuilder = _buildMainScreen,
  });

  final KlimmeckGraphQl graphQl;

  /// Sostituibile solo nei test, per non montare il MainScreen che fa rete.
  final WidgetBuilder mainScreenBuilder;

  static Widget _buildMainScreen(BuildContext context) => const MainScreen();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StorageCubit>(create: (_) => StorageCubit()),
        BlocProvider<CharacterCubit>(create: (_) => CharacterCubit(graphQl)),
        BlocProvider<QuestCubit>(create: (_) => QuestCubit(graphQl)),
        BlocProvider<TransactionCubit>(
          create: (_) => TransactionCubit(graphQl),
        ),
        BlocProvider<MainScreenCubit>(create: (_) => MainScreenCubit(graphQl)),
        BlocProvider<WorldMapCubit>(create: (_) => WorldMapCubit(graphQl)),
        BlocProvider<ShopCubit>(create: (_) => ShopCubit(graphQl)),
        BlocProvider<LibraryCubit>(create: (_) => LibraryCubit(graphQl)),
        BlocProvider<JournalCubit>(create: (_) => JournalCubit(graphQl)),
      ],
      child: _ShellBody(mainScreenBuilder: mainScreenBuilder),
    );
  }
}

class _ShellBody extends StatefulWidget {
  const _ShellBody({required this.mainScreenBuilder});

  final WidgetBuilder mainScreenBuilder;

  @override
  State<_ShellBody> createState() => _ShellBodyState();
}

class _ShellBodyState extends State<_ShellBody> {
  @override
  void initState() {
    super.initState();
    context.read<SplashCubit>().getImages('main');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplashCubit, SplashState>(
      builder: (context, state) => _isPreloadSettled(state)
          ? widget.mainScreenBuilder(context)
          : const SplashScreen(),
    );
  }

  /// Un preload fallito non blocca: `CachedSvg` ricade sulla rete.
  static bool _isPreloadSettled(SplashState state) =>
      state is SplashData || state is SplashError;
}
