import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_notice.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/companion_lines.dart';
import 'package:klimmeck_guide/utils/name_rules.dart';

/// Apre il foglio del nome sul navigator radice, fuori dai provider della
/// shell: il cubit gli arriva per valore, ripulito da un esito precedente.
/// Niente trascinamento: chiuderebbe il foglio anche a richiesta in volo.
Future<void> showCompanionNameSheet(
  BuildContext context, {
  required String characterId,
  required String petId,
  required String species,
  String? initialName,
}) {
  final cubit = context.read<CompanionNameCubit>()..reset();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: false,
    isScrollControlled: true,
    enableDrag: false,
    elevation: 0,
    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider<CompanionNameCubit>.value(
      value: cubit,
      child: CompanionNameSheet(
        characterId: characterId,
        petId: petId,
        species: species,
        initialName: initialName,
      ),
    ),
  );
}

/// Pergamena del nome del compagno (D-18, D-19, D-31): stesse regole di
/// forma del nome del personaggio, rifiuto del backend sotto il campo,
/// «Chiamalo così» / «Più tardi». Alta quanto il contenuto e sollevata
/// sopra la tastiera: in orizzontale il campo resta in vista (Pitfall 6).
/// Mentre la richiesta è in volo le azioni sono spente, nessun indicatore.
/// Stile provvisorio.
class CompanionNameSheet extends StatefulWidget {
  const CompanionNameSheet({
    super.key,
    required this.characterId,
    required this.petId,
    required this.species,
    this.initialName,
  });

  final String characterId;
  final String petId;
  final String species;
  final String? initialName;

  static const Key fieldKey = ValueKey('companion.name.field');
  static const Key errorKey = ValueKey('companion.name.error');
  static const Key refusalKey = ValueKey('companion.name.refusal');
  static const Key confirmKey = ValueKey('companion.name.confirm');
  static const Key skipKey = ValueKey('companion.name.skip');

  @override
  State<CompanionNameSheet> createState() => _CompanionNameSheetState();
}

class _CompanionNameSheetState extends State<CompanionNameSheet> {
  static const Size _minTapTarget = Size(44, 44);
  static const double _roomyHeight = 150;

  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<CompanionNameCubit, CompanionNameState>(
        listenWhen: (_, current) =>
            current is CompanionNameSaved && current.petId == widget.petId,
        listener: (context, _) => _close(context),
        builder: (context, state) => PopScope(
          canPop: state is! CompanionNameSubmitting,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: _parchment(context, state),
          ),
        ),
      );

  /// `pop` e non `maybePop`: il PopScope può ancora bloccare l'uscita da
  /// `CompanionNameSubmitting` finché non si ricostruisce.
  void _close(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context).pop();
  }

  /// Pergamena ancorata in alto: il bordo strappato resta in vista e il
  /// contenuto parte sotto di esso.
  Widget _parchment(BuildContext context, CompanionNameState state) {
    final width = MediaQuery.sizeOf(context).width;
    return Stack(
      children: [
        Positioned.fill(
          child: CachedSvg(
            url: CloudinaryAssets.url(CloudinaryAssets.bottomEmptySheet),
            width: width,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: width / 7,
            right: width / 7,
            top: _topMargin(context),
            bottom: KlimmeckGuideTheme.spacingXs,
          ),
          child: SingleChildScrollView(child: _content(context, state)),
        ),
      ],
    );
  }

  /// Il margine sotto il bordo strappato cede quando la tastiera lascia
  /// troppo poco spazio: il campo resta in vista (Pitfall 6).
  double _topMargin(BuildContext context) {
    final free =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    return free < _roomyHeight
        ? KlimmeckGuideTheme.spacingXs
        : KlimmeckGuideTheme.spacingLg;
  }

  Widget _content(BuildContext context, CompanionNameState state) {
    final isSubmitting = state is CompanionNameSubmitting;
    final canConfirm =
        !isSubmitting && nameErrorOf(_controller.text) == null && !_isUnchanged;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: AutoSizeText(
                companionNamePromptTitle(widget.species),
                maxLines: 2,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: KlimmeckGuideTheme.spacingSm),
            SizedBox(
              width: KlimmeckGuideTheme.inputTextWidth,
              child: _field(state, canConfirm: canConfirm),
            ),
          ],
        ),
        ?_line(
          nameErrorOf(_controller.text)?.message,
          key: CompanionNameSheet.errorKey,
        ),
        ?_line(_refusalOf(state), key: CompanionNameSheet.refusalKey),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              child: _action(
                key: CompanionNameSheet.skipKey,
                label: companionNameSkipLabel,
                color: KlimmeckGuideTheme.darkWood,
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(context).maybePop(),
              ),
            ),
            Flexible(
              child: _action(
                key: CompanionNameSheet.confirmKey,
                label: companionNameConfirmLabel,
                color: KlimmeckGuideTheme.healGreen,
                onPressed: canConfirm ? _confirm : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(CompanionNameState state, {required bool canConfirm}) =>
      TextField(
        key: CompanionNameSheet.fieldKey,
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: companionNameFieldLabel),
        onChanged: (_) => _edited(state),
        onSubmitted: (_) {
          if (canConfirm) _confirm();
        },
      );

  /// Riscrivere dopo un rifiuto lo toglie dal foglio (lezione di review).
  void _edited(CompanionNameState state) {
    setState(() {});
    if (state is CompanionNameRefused) {
      context.read<CompanionNameCubit>().reset();
    }
  }

  /// Lo stesso nome di adesso non manda una richiesta inutile (D-19).
  bool get _isUnchanged =>
      normalizedNameOf(_controller.text) == widget.initialName;

  void _confirm() => context.read<CompanionNameCubit>().rename(
    characterId: widget.characterId,
    petId: widget.petId,
    name: normalizedNameOf(_controller.text),
  );

  String? _refusalOf(CompanionNameState state) => switch (state) {
    CompanionNameRefused(:final petId, :final failure)
        when petId == widget.petId =>
      companionNameRefusalLine(failure),
    _ => null,
  };

  Widget? _line(String? text, {required Key key}) {
    if (text == null) return null;
    return Padding(
      padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingXs),
      child: Text(
        text,
        key: key,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _action({
    required Key key,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) => Semantics(
    label: label,
    button: true,
    child: TextButton(
      key: key,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: _minTapTarget,
        foregroundColor: color,
      ),
      child: AutoSizeText(label, maxLines: 1),
    ),
  );
}
