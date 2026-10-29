import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/account_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/innkeeper_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart';
import 'package:klimmeck_guide/shared/components/background_image.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Tab Impostazioni (settima voce della borsa, D-01/D-04): foglio di
/// pergamena come Profilo, senza AppBar né Scaffold.
class Settings extends StatelessWidget {
  const Settings({super.key});

  static const double _satchelClearance = 120;
  static const double _sheetHorizontalMargin = 50;

  @override
  Widget build(BuildContext context) {
    return BackgroundImage(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _sheetHorizontalMargin),
        child: Container(
          decoration: const BoxDecoration(color: KlimmeckGuideTheme.parchment),
          child: BlocSelector<CharacterCubit, CharacterState, String?>(
            selector: (state) =>
                state is CharacterLoaded ? state.character.infos?.name : null,
            builder: (context, name) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: KlimmeckGuideTheme.spacingLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: KlimmeckGuideTheme.spacingXl),
                  Text(
                    'Impostazioni',
                    style: KlimmeckGuideTheme.instance.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (name != null) ...[
                    const SizedBox(height: KlimmeckGuideTheme.spacingSm),
                    Text(
                      name,
                      style: KlimmeckGuideTheme.instance.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: KlimmeckGuideTheme.spacingLg),
                  const NotificationPreferencesSection(),
                  const SizedBox(height: KlimmeckGuideTheme.spacingXl),
                  const InnkeeperSection(),
                  AccountSection(characterName: name),
                  const SizedBox(height: _satchelClearance),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
