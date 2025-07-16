import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klimmeck_guide/repository/storage/storage_manager.dart';
import 'package:klimmeck_guide/shared/components/kg_error.dart';

import '../../main.dart';
import '../../models/user.dart';
import '../../routes/routes.dart';
import '../../shared/components/card_icon.dart';
import '../../shared/components/card_icon_list.dart';
import '../../shared/components/title_icons.dart';
import '../../theme/kg_theme.dart';
import 'cubit/profile_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user} );

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<String> suppliesAt = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLogOut) {
          logOut();
        }
        if (state is ProfileReset) {
          Future.delayed(const Duration(milliseconds: 5000), () {
            context.read<ProfileCubit>().logout();
          });
        }
        if (state is ProfileResetError) {
          Future.delayed(const Duration(milliseconds: 5000), () {
            context.read<ProfileCubit>().startManagement();
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: KlimmeckGuideTheme.deepNight,
          body: SafeArea(
            child: Column(
              children: [
                TitleAndIcons(
                  title: 'welcome',
                  hasBackButton: true,
                  subTitle:
                      widget.user.name,
                  isProfile: true,
                  user: widget.user,
                ),
                if (state is ProfileData)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 30.0, right: 30, top: 40.0),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.75,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (suppliesAt.isNotEmpty && suppliesAt.length > 1)
                              CardIconList(
                                title: "yourSuppliesAt",
                                contents: suppliesAt,
                                icon: "assets/icons/utils/position.svg",
                                maxLines: 2,
                                iconColor: KlimmeckGuideTheme.parchment,
                              ),
                            if (suppliesAt.isNotEmpty && suppliesAt.length == 1)
                              CardIcon(
                                title: "yourSuppliesAt",
                                content: suppliesAt.first,
                                icon: "assets/icons/utils/position.svg",
                                maxLines: 2,
                                iconColor: KlimmeckGuideTheme.parchment,
                              ),
                            if (suppliesAt.isNotEmpty)
                              const SizedBox(height: 30),
                            CardIcon(
                              title: "youruserCode",
                              content: widget.user.id,
                              iconColor: KlimmeckGuideTheme.deepNight,
                              icon: "assets/icons/utils/copy_line.svg",
                              onTap: () => {
                                Clipboard.setData(ClipboardData(
                                        text: widget.user.email))
                                    .then((value) {
                                  var snackBar = SnackBar(
                                    content: const Text('Copied to Clipboard'),
                                    backgroundColor:
                                        Colors.black.withOpacity(0.4),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                })
                              },
                            ),
                            const SizedBox(height: 30),
                            CardIcon(
                              title: "yourContracts",
                              content: "Visualizza lo stato dei tuoi contratti",
                              icon: 'assets/icons/utils/payments_line.svg',
                              iconColor: KlimmeckGuideTheme.deepNight,
                              maxLines: 2,
                              onTap: () => {}
                            ),
                            const SizedBox(height: 30),
                            CardIcon(
                              content: "Modifica la tua password",
                              icon: "assets/icons/utils/edit_line.svg",
                              maxLines: 2,
                              iconColor: KlimmeckGuideTheme.deepNight,
                              onTap: () async {
                                var user =
                                    await KGStorageManager.getLoggedUser();
                                if (user != null) {
                                  context
                                      .read<ProfileCubit>()
                                      .resetPassword(user.email);
                                }
                              },
                            ),
                            const SizedBox(height: 30),
                            CardIcon(
                              content: "Effettua il logout",
                              icon: "assets/icons/utils/logout.svg",
                              maxLines: 2,
                              iconColor: KlimmeckGuideTheme.deepNight,
                              onTap: () =>
                                  context.read<ProfileCubit>().logout(),
                            ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (state is ProfileError)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 30.0, right: 30, top: 40),
                    child: RefreshIndicator(
                      onRefresh: () =>
                          context.read<ProfileCubit>().startManagement(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                            height: MediaQuery.of(context).size.height -
                                (160 +
                                    MediaQuery.of(context).size.width * 0.13 +
                                    MediaQuery.of(context).viewPadding.bottom +
                                    MediaQuery.of(context).viewPadding.top),
                            child: const KGError()),
                      ),
                    ),
                  ),
                if (state is ProfileReset || state is ProfileResetError)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 30.0, right: 30, top: 40),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          (160 +
                              MediaQuery.of(context).size.width * 0.13 +
                              MediaQuery.of(context).viewPadding.bottom +
                              MediaQuery.of(context).viewPadding.top),
                      child: Column(
                        children: [
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 30.0, right: 30, top: 40),
                            child: SvgPicture.asset(
                              state is ProfileReset
                                  ? "assets/icons/payments/lucy_success.svg"
                                  : "assets/icons/payments/lucy_failed.svg",
                              height: MediaQuery.of(context).size.height * 0.3,
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 20,
                                left: 30.0,
                                right: 30,
                              ),
                              child: Text(
                                state is ProfileReset
                                    ? "Abbiamo inviato una mail al tuo indirizzo per reimpostare la password"
                                    : state is ProfileResetError
                                        ? state.errorMessage
                                        : "",
                                style: KlimmeckGuideTheme.instance
                                    .bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Spacer()
                        ],
                      ),
                    ),
                  ),
                if (state is ProfileLoading || state is ProfileLogOut)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 30.0, right: 30, top: 40),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          (160 +
                              MediaQuery.of(context).size.width * 0.13 +
                              MediaQuery.of(context).viewPadding.bottom +
                              MediaQuery.of(context).viewPadding.top),
                      child: Column(
                        children: const [Spacer(), KGError(), Spacer()],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> logOut() async {
    await FirebaseMessaging.instance.deleteToken();
    await KGStorageManager.logOut();
    navigatorKey.currentState?.popUntil((route) => false);
    navigatorKey.currentState?.push(signInRoute());
  }

}
