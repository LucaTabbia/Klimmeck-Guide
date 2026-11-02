import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart';

/// Carica il pool della città del marker (D-01, D-03): al montaggio della
/// pagina (il PageView ricrea la tab a ogni apertura, research C1), quando il
/// personaggio arriva in un'altra città con la pagina a schermo e dopo un
/// rifiuto `ITEM_NOT_IN_SHOP` (D-05). Nessun visual.
class ShopPoolLoader extends StatefulWidget {
  const ShopPoolLoader({super.key, required this.cities, required this.child});

  final List<City> cities;
  final Widget child;

  @override
  State<ShopPoolLoader> createState() => _ShopPoolLoaderState();
}

class _ShopPoolLoaderState extends State<ShopPoolLoader> {
  @override
  void initState() {
    super.initState();
    _load(context.read<CharacterCubit>().state);
  }

  String? _cityIdOf(CharacterState state) => state is CharacterLoaded
      ? currentCityOf(widget.cities, state.character.status?.location)?.id
      : null;

  void _load(CharacterState state) {
    final cityId = _cityIdOf(state);
    if (cityId == null) return;
    context.read<ShopCubit>().getData(cityId);
  }

  bool _isStaleRowRefusal(TransactionState state) =>
      state is TransactionError &&
      state.failure == TransactionFailure.itemNotInShop;

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: (previous, current) =>
            _cityIdOf(previous) != _cityIdOf(current),
        listener: (_, state) => _load(state),
      ),
      BlocListener<TransactionCubit, TransactionState>(
        listenWhen: (_, current) => _isStaleRowRefusal(current),
        listener: (context, _) => _load(context.read<CharacterCubit>().state),
      ),
    ],
    child: widget.child,
  );
}
