import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/bloc/location_bloc.dart';
import 'package:amaguexpress/src/common/file_helper.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/src/screens/profile/profile_controller.dart';
import 'package:amaguexpress/src/screens/profile/widget/amount_input.dart';
import 'package:amaguexpress/src/screens/profile/widget/balance_input.dart';
import 'package:amaguexpress/src/screens/profile/widget/change_password_button.dart';
import 'package:amaguexpress/src/screens/profile/widget/email_input.dart';
import 'package:amaguexpress/src/screens/profile/widget/name_input.dart';
import 'package:amaguexpress/src/screens/profile/widget/phone_input.dart';
import 'package:amaguexpress/src/screens/profile/widget/save_button.dart';
import 'package:amaguexpress/src/screens/welcome/welcome_screen.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';
import 'package:amaguexpress/src/widgets/confirmation_dialog.dart';
import 'package:amaguexpress/src/widgets/modal_progress_hud.dart';
import 'package:amaguexpress/src/widgets/money_input.dart';
import 'package:amaguexpress/src/widgets/upload_file/upload_file.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final pref = PreferencesProvider();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileController>.value(
      value: ProfileController(),
      child: Consumer<ProfileController>(
        builder: (context, profileController, child) => Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: kPrimaryColor,
            title: Text(pref.user.fullName),
            actions: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ConfirmationDialog(
                      S.of(context).mDLogoutSession,
                      labelOk: S.of(context).bAccept,
                      iconOk: const Icon(Icons.output_outlined),
                      onPressedOk: () {
                        _logOut(context, profileController);
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.output_outlined, size: 30),
              )
            ],
          ),
          body: ModalProgressHUD(
            inAsyncCall: profileController.inAsyncCall,
            child: SafeArea(
              top: true,
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: kDefaultPadding,
                        right: kDefaultPadding,
                        top: kDefaultPadding * 1.3,
                        bottom: kDefaultPadding,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) =>
                                      UploadFile((image) async {
                                    profileController.inAsyncCall = true;
                                    String imageUpload = await uploadFile(
                                      image,
                                      'user/${pref.user.id}',
                                      '${pref.user.id}-${DateTime.now().toIso8601String()}',
                                      kTargetWidthUser,
                                    );
                                    profileController.changeImage(imageUpload);
                                  }),
                                );
                              },
                              child: CircularPercentIndicator(
                                radius: 50.0,
                                lineWidth: 3.0,
                                percent: 1.0,
                                center: AvatarImage(
                                  width: 80,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(100)),
                                  image: pref.user.image,
                                ),
                                progressColor: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: kDefaultPadding * 1.3),
                            if (pref.user.roles.contains(TypesRol.deliveryman))
                              _contentDeliveryMan(context, profileController),
                            if (!pref.user.roles.contains(TypesRol.deliveryman))
                              _contentIsNotDeliveryMan(
                                  context, profileController),
                            const SizedBox(height: kDefaultPadding * 2.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: kDefaultPadding,
                      right: kDefaultPadding,
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    child: ProfileButton(profileController, formKey: formKey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contentDeliveryMan(
      BuildContext context, ProfileController profileController) {
    return Column(
      children: [
        BalanceInput(profileController.balance.balance),
        const SizedBox(height: kDefaultPadding * 1.3),
        AmountInput(profileController.balance.amount),
        const SizedBox(height: kDefaultPadding * 1.3),
        PhoneInput(profileController),
        const SizedBox(height: kDefaultPadding * 1.3),
        EmailInput(profileController),
        const SizedBox(height: kDefaultPadding * 2.6),
        ChangePasswordButton(profileController),
        const SizedBox(height: kDefaultPadding * 0.8),
        _deleteAccountButton(context),
      ],
    );
  }

  Widget _contentIsNotDeliveryMan(
      BuildContext context, ProfileController profileController) {
    return Column(
      children: [
        MoneyInput(profileController.balance.money),
        const SizedBox(height: kDefaultPadding * 0.5),
        NameInput(profileController),
        const SizedBox(height: kDefaultPadding * 0.5),
        PhoneInput(profileController),
        const SizedBox(height: kDefaultPadding * 0.5),
        EmailInput(profileController),
        const SizedBox(height: kDefaultPadding * 1.3),
        ChangePasswordButton(profileController),
        const SizedBox(height: kDefaultPadding * 0.8),
        _deleteAccountButton(context),
      ],
    );
  }

  Widget _deleteAccountButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                backgroundColor: const Color(0xFF1F1F1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Colors.white24, width: 1.2),
                ),
                title: const Text(
                  'Eliminar cuenta',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'La eliminación de la cuenta es definitiva y no se puede deshacer. ¿Deseas continuar?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: const Color(0xFF8B0000),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Continuar'),
                  ),
                ],
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.grey.shade700,
            foregroundColor: const Color(0xFF8B0000),
            side: const BorderSide(color: Color(0xFF8B0000), width: 1.1),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: const Text('Eliminar cuenta'),
        ),
      ),
    );
  }

  _logOut(BuildContext context, ProfileController profileController) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final s = S.of(context);
    bool islogOut = await profileController.logOut();

    if (!islogOut && !pref.isGuest) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(s.errUnknown),
      ));
      return;
    }

    if (pref.user.roles.contains(TypesRol.deliveryman)) {
      LocationBloc().stop();
    }

    pref.clean();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (Route<dynamic> route) => false,
    );
  }
}
