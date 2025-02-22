import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages_desktop_specific/home/desktop_home_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:stackwallet/widgets/progress_bar.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:zxcvbn/zxcvbn.dart';

class CreatePasswordView extends StatefulWidget {
  const CreatePasswordView({
    Key? key,
    this.secureStore = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
  }) : super(key: key);

  static const String routeName = "/createPasswordDesktop";

  final FlutterSecureStorageInterface secureStore;

  @override
  State<CreatePasswordView> createState() => _CreatePasswordViewState();
}

class _CreatePasswordViewState extends State<CreatePasswordView> {
  late final TextEditingController passwordController;
  late final TextEditingController passwordRepeatController;

  late final FocusNode passwordFocusNode;
  late final FocusNode passwordRepeatFocusNode;
  final zxcvbn = Zxcvbn();

  String passwordFeedback =
      "Add another word or two. Uncommon words are better. Use a few words, avoid common phrases. No need for symbols, digits, or uppercase letters.";
  bool shouldShowPasswordHint = true;
  bool hidePassword = true;
  double passwordStrength = 0.0;

  bool get nextEnabled =>
      passwordController.text.isNotEmpty &&
      passwordRepeatController.text.isNotEmpty;

  bool get fieldsMatch =>
      passwordController.text == passwordRepeatController.text;

  void onNextPressed() async {
    final String passphrase = passwordController.text;
    final String repeatPassphrase = passwordRepeatController.text;

    if (passphrase.isEmpty) {
      unawaited(showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "A password is required",
        context: context,
      ));
      return;
    }
    if (passphrase != repeatPassphrase) {
      unawaited(showFloatingFlushBar(
        type: FlushBarType.warning,
        message: "Password does not match",
        context: context,
      ));
      return;
    }

    await widget.secureStore
        .write(key: "stackDesktopPassword", value: passphrase);

    if (mounted) {
      unawaited(Navigator.of(context)
          .pushReplacementNamed(DesktopHomeView.routeName));
    }

    unawaited(showFloatingFlushBar(
      type: FlushBarType.success,
      message: "Your password is set up",
      context: context,
    ));
  }

  @override
  void initState() {
    passwordController = TextEditingController();
    passwordRepeatController = TextEditingController();

    passwordFocusNode = FocusNode();
    passwordRepeatFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    passwordController.dispose();
    passwordRepeatController.dispose();

    passwordFocusNode.dispose();
    passwordRepeatFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType ");

    return DesktopScaffold(
      appBar: DesktopAppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        isCompactHeight: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Create a password",
                      style: STextStyles.desktopH2(context),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      "Protect your funds with a strong password",
                      style: STextStyles.desktopSubtitleH2(context),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                      child: TextField(
                        key: const Key("createBackupPasswordFieldKey1"),
                        focusNode: passwordFocusNode,
                        controller: passwordController,
                        style: STextStyles.desktopTextMedium(context).copyWith(
                          height: 2,
                        ),
                        obscureText: hidePassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: standardInputDecoration(
                          "Create password",
                          passwordFocusNode,
                          context,
                        ).copyWith(
                          suffixIcon: UnconstrainedBox(
                            child: SizedBox(
                              height: 70,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    key: const Key(
                                        "createDesktopPasswordFieldShowPasswordButtonKey"),
                                    onTap: () async {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(1000),
                                      ),
                                      height: 32,
                                      width: 32,
                                      child: Center(
                                        child: SvgPicture.asset(
                                          hidePassword
                                              ? Assets.svg.eye
                                              : Assets.svg.eyeSlash,
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .textDark3,
                                          width: 24,
                                          height: 19,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        onChanged: (newValue) {
                          if (newValue.isEmpty) {
                            setState(() {
                              passwordFeedback = "";
                            });
                            return;
                          }
                          final result = zxcvbn.evaluate(newValue);
                          String suggestionsAndTips = "";
                          for (var sug
                              in result.feedback.suggestions!.toSet()) {
                            suggestionsAndTips += "$sug\n";
                          }
                          suggestionsAndTips += result.feedback.warning!;
                          String feedback =
                              // "Password Strength: ${((result.score! / 4.0) * 100).toInt()}%\n"
                              suggestionsAndTips;

                          passwordStrength = result.score! / 4;

                          // hack fix to format back string returned from zxcvbn
                          if (feedback.contains("phrasesNo need")) {
                            feedback = feedback.replaceFirst(
                                "phrasesNo need", "phrases\nNo need");
                          }

                          if (feedback.endsWith("\n")) {
                            feedback =
                                feedback.substring(0, feedback.length - 2);
                          }

                          setState(() {
                            passwordFeedback = feedback;
                          });
                        },
                      ),
                    ),
                    if (passwordFocusNode.hasFocus ||
                        passwordRepeatFocusNode.hasFocus ||
                        passwordController.text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: passwordFeedback.isNotEmpty ? 4 : 8,
                        ),
                        child: passwordFeedback.isNotEmpty
                            ? Text(
                                passwordFeedback,
                                style:
                                    STextStyles.desktopTextExtraSmall(context)
                                        .copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .textSubtitle1,
                                ),
                              )
                            : null,
                      ),
                    if (passwordFocusNode.hasFocus ||
                        passwordRepeatFocusNode.hasFocus ||
                        passwordController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                        ),
                        child: ProgressBar(
                          key: const Key("createDesktopPasswordProgressBar"),
                          width: 458,
                          height: 8,
                          fillColor: passwordStrength < 0.51
                              ? Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorRed
                              : passwordStrength < 1
                                  ? Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorYellow
                                  : Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorGreen,
                          backgroundColor: Theme.of(context)
                              .extension<StackColors>()!
                              .buttonBackSecondary,
                          percent:
                              passwordStrength < 0.25 ? 0.03 : passwordStrength,
                        ),
                      ),
                    const SizedBox(
                      height: 16,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                      child: TextField(
                        key: const Key("createDesktopPasswordFieldKey2"),
                        focusNode: passwordRepeatFocusNode,
                        controller: passwordRepeatController,
                        style: STextStyles.desktopTextMedium(context).copyWith(
                          height: 2,
                        ),
                        obscureText: hidePassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: standardInputDecoration(
                          "Confirm password",
                          passwordRepeatFocusNode,
                          context,
                        ).copyWith(
                          suffixIcon: UnconstrainedBox(
                            child: SizedBox(
                              height: 70,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    key: const Key(
                                        "createDesktopPasswordFieldShowPasswordButtonKey2"),
                                    onTap: () async {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(1000),
                                      ),
                                      height: 32,
                                      width: 32,
                                      child: Center(
                                        child: SvgPicture.asset(
                                          fieldsMatch && passwordStrength == 1
                                              ? Assets.svg.checkCircle
                                              : hidePassword
                                                  ? Assets.svg.eye
                                                  : Assets.svg.eyeSlash,
                                          color: fieldsMatch &&
                                                  passwordStrength == 1
                                              ? Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorGreen
                                              : Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .textDark3,
                                          width: 24,
                                          height: 19,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        onChanged: (newValue) {
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    SizedBox(
                      width: 480,
                      height: 70,
                      child: TextButton(
                        style: nextEnabled
                            ? Theme.of(context)
                                .extension<StackColors>()!
                                .getPrimaryEnabledButtonColor(context)
                            : Theme.of(context)
                                .extension<StackColors>()!
                                .getPrimaryDisabledButtonColor(context),
                        onPressed: nextEnabled ? onNextPressed : null,
                        child: Text(
                          "Next",
                          style: nextEnabled
                              ? STextStyles.desktopButtonEnabled(context)
                              : STextStyles.desktopButtonDisabled(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: kDesktopAppBarHeight,
          ),
        ],
      ),
    );
  }
}
