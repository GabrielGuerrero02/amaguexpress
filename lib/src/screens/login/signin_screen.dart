import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/login/access_controller.dart';
import 'package:amaguexpress/src/screens/login/widget/email_input.dart';
import 'package:amaguexpress/src/screens/login/widget/google_button.dart';
import 'package:amaguexpress/src/screens/login/widget/password_input.dart';
import 'package:amaguexpress/src/screens/login/widget/signin_button.dart';
import 'package:amaguexpress/src/screens/login/widget/tabs_button.dart';
import 'package:amaguexpress/src/screens/welcome/welcome_screen.dart';
import 'package:amaguexpress/src/screens/recover/recover_screen.dart';
import 'package:amaguexpress/src/widgets/modal_progress_hud.dart';
import 'package:provider/provider.dart';

class SigninScreen extends StatelessWidget {
  SigninScreen({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AccessController>.value(
      value: AccessController(),
      child: Scaffold(
        body: Consumer<AccessController>(
          builder: (context, accessController, child) => ModalProgressHUD(
            inAsyncCall: accessController.inAsyncCall,
            child: Center(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(kDefaultPadding),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const WelcomeScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: kDefaultPadding * 1.2),
                        Image.asset("assets/screen/icon.png", height: 105),
                        const SizedBox(height: kDefaultPadding * 1.3),
                        const TabsButton(isPageSignin: true),
                        const SizedBox(height: kDefaultPadding * 1.3),
                        EmailInput(accessController),
                        const SizedBox(height: kDefaultPadding * 1.3),
                        PasswordInput(accessController),
                        const SizedBox(height: kDefaultPadding * 1.3),
                        SigninButton(accessController, formKey: _formKey),
                        const SizedBox(height: kDefaultPadding * 1.3),
                        if (!kIsWeb && !Platform.isIOS) ...[
                          const SizedBox(height: kDefaultPadding * 1.3),
                          GoogleButton(accessController),
                        ],
                        const SizedBox(height: kDefaultPadding * 1.3),
                        TextButton(
                          child: Text(S.of(context).bRecoverAccount),
                          onPressed: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecoverScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: kDefaultPadding * 7),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
