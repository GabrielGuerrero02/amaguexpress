import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/code_error_constant.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/recover/recover_controller.dart';
import 'package:amaguexpress/src/widgets/confirmation_dialog.dart';
import 'package:amaguexpress/src/widgets/primary_button.dart';

class RecoverButton extends StatelessWidget {
  const RecoverButton(
    this.recoverController, {
    super.key,
    required GlobalKey<FormState> formKey,
  }) : _formKey = formKey;
  final RecoverController recoverController;
  final GlobalKey<FormState> _formKey;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: S.of(context).bRecoverAccount,
      onPressed: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        _formKey.currentState!.save();
        if (!_formKey.currentState!.validate()) return;

        final s = S.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        recoverController.inAsyncCall = true;
        final codeError = await recoverController.recover();
        recoverController.inAsyncCall = false;
        String? error;

        switch (codeError) {
          case CodeError.none:
            if (context.mounted) showConfirmationDialog(context, s);
            return;
          case CodeError.unknown:
            error = s.errUnknown;
            break;
          case CodeError.accountnotexist:
            error = s.errRecoverAccount(recoverController.email);
            break;
          default:
        }

        if (error != null) {
          scaffoldMessenger.showSnackBar(SnackBar(
              backgroundColor: kErrorColor,
              duration: const Duration(milliseconds: 4500),
              content: Text(error)));
        }
      },
    );
  }

  showConfirmationDialog(BuildContext context, S s) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => ConfirmationDialog(
          s.mRecoverAccount(recoverController.email),
          showButtonCancell: false,
          iconOk: const Icon(Icons.mark_email_unread_outlined),
          labelOk: s.bDone, onPressedOk: () async {
        Navigator.of(context).pop();
      }),
    );
  }
}
