
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../shared/components/kg_button.dart';
import '../../shared/components/kg_input_text.dart';
import '../../shared/components/kg_loader.dart';
import '../../shared/components/simple_title.dart';
import '../../theme/kg_theme.dart';
import 'cubit/sign_in_cubit.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool isResetting = false;
  String errorMessage = "";
  bool showError = false;
  bool hidePassword = true;
  bool isValid = false;
  String? deviceId;

  @override
  void initState() {

    emailController.addListener(() {
      if (emailController.text != "" &&
          emailController.text.contains("@") &&
          passwordController.text != "") {
        setState(() {
          isValid = true;
        });
      } else {
        setState(() {
          isValid = false;
        });
      }
    });
    passwordController.addListener(() {
      if (emailController.text != "" &&
          emailController.text.contains("@") &&
          passwordController.text != "") {
        setState(() {
          isValid = true;
        });
      } else {
        setState(() {
          isValid = false;
        });
      }
    });
    context.read<SignInCubit>().startLogIn();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInCubit, SignInState>(
      listener: (context, state) {
        if (state is SignInReset || state is SignInResetError) {
          setState(() {
            isResetting = false;
          });
          Future.delayed(const Duration(milliseconds: 5000), () {
            context.read<SignInCubit>().startLogIn();
          });
        }
      },
      builder: (context, state) {
        if (state is SignInLoading || state is SignInData) {
          return Scaffold(
            backgroundColor: KlimmeckGuideTheme.deepNight,
            body: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).viewPadding.top +
                        MediaQuery.of(context).viewPadding.bottom),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SimpleTitle(
                        title: 'login', subtitle: 'loginOrSignIn'),
                    Expanded(
                        child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height -
                              (160 +
                                  MediaQuery.of(context).viewPadding.top +
                                  MediaQuery.of(context).viewPadding.bottom),
                          child: Column(
                            children: const [
                              Spacer(),
                              KGLoader(),
                              Spacer(),
                            ],
                          ),
                        )
                      ],
                    ))
                  ],
                ),
              ),
            ),
          );
        }
        if (state is SignInReset || state is SignInResetError) {
          return Scaffold(
            backgroundColor: KlimmeckGuideTheme.deepNight,
            body: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).viewPadding.top +
                        MediaQuery.of(context).viewPadding.bottom),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SimpleTitle(
                        title: 'login', subtitle: 'resetPassword'),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(left: 30.0, right: 30, top: 40),
                      child: SvgPicture.asset(
                        state is SignInReset
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
                          state is SignInReset
                              ? "Abbiamo inviato una mail al tuo indirizzo per reimpostare la password"
                              : state is SignInResetError
                                  ? state.error
                                  : "",
                          style: KlimmeckGuideTheme.instance.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: KlimmeckGuideTheme.deepNight,
          body: SafeArea(
            child: InkWell(
              onTap: () {
                FocusScopeNode currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
                  currentFocus.focusedChild!.unfocus();
                }
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).viewPadding.top +
                        MediaQuery.of(context).viewPadding.bottom),
                width: MediaQuery.of(context).size.width,
                child: isResetting ? resetForm(state) : signInForm(state),
              ),
            ),
          ),
        );
      },
    );
  }

  /*Future<String?> getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      deviceId = iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      deviceId = androidDeviceInfo.id; // unique ID on Android
    }
  }*/

  Widget confirmButton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: emailController.text != "" &&
                  emailController.text.contains("@") &&
                  passwordController.text != ""
              ? 1
              : 0.6,
          child: KGButton(
              text: "confirm",
              onTap: () => {
                    if (emailController.text != "" &&
                        emailController.text.contains("@") &&
                        passwordController.text != "")
                      context
                          .read<SignInCubit>()
                          .logIn(emailController.text, passwordController.text)
                  }),
        ),
      ],
    );
  }

  Widget resetButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: () => setState(() {
            isResetting = false;
            emailController.clear();
          }),
          child: Container(
            height: 40,
            width: (MediaQuery.of(context).size.width - 60) * 0.40,
            decoration: BoxDecoration(
                border: Border.all(color: KlimmeckGuideTheme.parchment, width: 1),
                borderRadius: const BorderRadius.all(Radius.circular(KlimmeckGuideTheme.radius))),
            child: Center(
              child: Text(
                "goBack",
                style: KlimmeckGuideTheme.instance.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () => {
            if (emailController.text != "" && emailController.text.contains("@"))
              context.read<SignInCubit>().resetPassword(emailController.text)
          },
          child: Container(
            height: 40,
            width: (MediaQuery.of(context).size.width - 60) * 0.40,
            decoration: BoxDecoration(
                color: emailController.text != "" && emailController.text.contains("@")
                    ? KlimmeckGuideTheme.primaryGold
                    : KlimmeckGuideTheme.primaryGold.withOpacity(0.4),
                borderRadius: const BorderRadius.all(Radius.circular(KlimmeckGuideTheme.radius))),
            child: Center(
              child: Text(
                "Conferma",
                style: KlimmeckGuideTheme.instance
                    .bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget resetForm(SignInState state) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30),
      child: Column(
        children: [
          SimpleTitle(
              title: 'login',
              subtitle:
                  isResetting ? 'resetPassword' : 'loginOrSignIn'),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height -
                      (160 +
                          MediaQuery.of(context).viewPadding.top +
                          MediaQuery.of(context).viewPadding.bottom),
                  child: Column(
                    children: [
                      const Spacer(),
                      KGInputText(
                        controller: emailController,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'hintEmail',
                        fieldName: 'yourEmail',
                        icon: 'assets/icons/utils/mail.svg',
                      ),
                      const Spacer(),
                      resetButtons(),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget signInForm(SignInState state) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30),
      child: Column(
        children: [
          SimpleTitle(
              title: 'login',
              subtitle:
                  isResetting ? 'resetPassword' : 'loginOrSignIn'),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height -
                      (160 +
                          MediaQuery.of(context).viewPadding.top +
                          MediaQuery.of(context).viewPadding.bottom),
                  child: Column(
                    children: [
                      const Spacer(),
                      KGInputText(
                        controller: emailController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'hintEmail',
                        fieldName: 'yourEmail',
                        icon: 'assets/icons/utils/mail.svg',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: KGInputText(
                          controller: passwordController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.text,
                          hideText: hidePassword,
                          hintText: 'hintPassword',
                          fieldName: 'yourPassword',
                          onTap: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                          icon: hidePassword
                              ? 'assets/icons/utils/hide_password.svg'
                              : 'assets/icons/utils/show_password.svg',
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Center(
                          child: InkWell(
                            onTap: () => setState(() {
                              isResetting = true;
                              emailController.clear();
                            }),
                            child: Text(
                              'forgotPassword',
                              style: KlimmeckGuideTheme.instance
                                  .bodyMedium,
                            ),
                          ),
                        ),
                      ),
                      if (state is SignInError)
                        Padding(
                            padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                            child: Center(
                              child: Text(
                                state.error,
                                style: KlimmeckGuideTheme.instance.errorText,
                                textAlign: TextAlign.center,
                              ),
                            )),
                      confirmButton(),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
