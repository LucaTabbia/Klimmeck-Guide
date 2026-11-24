import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/signIn/consentCubit/legal_consent_cubit.dart';
import 'package:klimmeck_guide/screens/signIn/cubit/sign_in_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

const String _acceptPrefix = 'Accetto i ';
const String _termsWording = 'Termini di servizio';
const String _joiner = " e l'";
const String _privacyWording = 'Informativa sulla privacy';
const String _sentence = '$_acceptPrefix$_termsWording$_joiner$_privacyWording';

/// Consenso ai documenti legali sopra il pulsante di login (D-07, D-08).
///
/// Le due diciture aprono la loro pagina e non toccano la spunta; il resto
/// della frase e la casella la cambiano. Per l'accessibilità la casella ha la
/// frase come etichetta e ogni link è un nodo a sé.
class LegalConsentRow extends StatefulWidget {
  const LegalConsentRow({super.key});

  @override
  State<LegalConsentRow> createState() => _LegalConsentRowState();
}

class _LegalConsentRowState extends State<LegalConsentRow> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.read<SignInCubit>().openTerms();
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.read<SignInCubit>().openPrivacy();
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consent = context.watch<LegalConsentCubit>();
    final isAccepted = consent.state.isAccepted;
    void toggle() => isAccepted ? consent.withdraw() : consent.accept();
    return Row(
      children: [
        Checkbox(
          value: isAccepted,
          onChanged: (_) => toggle(),
          semanticLabel: _sentence,
        ),
        Expanded(
          child: GestureDetector(
            onTap: toggle,
            excludeFromSemantics: true,
            child: Text.rich(_sentenceSpan()),
          ),
        ),
      ],
    );
  }

  TextSpan _sentenceSpan() {
    final plain = KlimmeckGuideTheme.instance.bodyMedium.copyWith(
      color: KlimmeckGuideTheme.parchment,
    );
    final link = plain.copyWith(
      color: KlimmeckGuideTheme.primaryGold,
      decoration: TextDecoration.underline,
      decorationColor: KlimmeckGuideTheme.primaryGold,
    );
    return TextSpan(
      style: plain,
      children: [
        const TextSpan(text: _acceptPrefix),
        TextSpan(
          text: _termsWording,
          style: link,
          recognizer: _termsRecognizer,
        ),
        const TextSpan(text: _joiner),
        TextSpan(
          text: _privacyWording,
          style: link,
          recognizer: _privacyRecognizer,
        ),
      ],
    );
  }
}
