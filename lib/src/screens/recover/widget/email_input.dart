import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/common/validator.dart';
import 'package:amaguexpress/src/screens/recover/recover_controller.dart';

class EmailInput extends StatelessWidget {
  const EmailInput(
    this.recoverController, {
    super.key,
  });
  final RecoverController recoverController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.75),
        margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.5),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1F1F1F)
              : const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black, // Borde negro
            width: 1, // Delgado
          ),
        ),
        child: TextFormField(
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            icon: const Icon(Icons.mail_lock_outlined, color: kPrimaryColor),
            hintText: S.of(context).hEmail,
            border: InputBorder.none,
          ),
          onSaved: (email) => recoverController.email = email!,
          validator: (value) => validateEmail(context, value!),
        ),
      ),
    );
  }
}
