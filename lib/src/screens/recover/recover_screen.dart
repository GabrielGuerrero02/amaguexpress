import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/src/screens/recover/recover_controller.dart';
import 'package:amaguexpress/src/screens/recover/widget/email_input.dart';
import 'package:amaguexpress/src/screens/recover/widget/recover_button.dart';
import 'package:amaguexpress/src/widgets/modal_progress_hud.dart';
import 'package:provider/provider.dart';

class RecoverScreen extends StatelessWidget {
  RecoverScreen({super.key});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final pref = PreferencesProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kPrimaryColor, // Usa tu color primario
          title: Text(S.of(context).bRecoverAccount)),
      body: ChangeNotifierProvider<RecoverController>.value(
        value: RecoverController(),
        child: Consumer<RecoverController>(
          builder: (context, recoverController, child) => ModalProgressHUD(
            inAsyncCall: recoverController.inAsyncCall,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomInset = MediaQuery.of(context).viewInsets.bottom;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      kDefaultPadding,
                      kDefaultPadding,
                      kDefaultPadding,
                      kDefaultPadding + bottomInset,
                    ),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('assets/screen/recover.png',
                                      width: 380),
                                  const SizedBox(height: kDefaultPadding),
                                  EmailInput(recoverController),
                                  const SizedBox(height: kDefaultPadding * 2),
                                ],
                              ),
                            ),
                            const SizedBox(height: kDefaultPadding),
                            RecoverButton(recoverController, formKey: formKey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
