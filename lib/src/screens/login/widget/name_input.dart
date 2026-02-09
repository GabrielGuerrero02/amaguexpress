import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/login/access_controller.dart';

class NameInput extends StatelessWidget {
  const NameInput(
    this.accessController, {
    super.key,
  });
  final AccessController accessController;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          icon: const Icon(Icons.nest_cam_wired_stand_outlined,
              color: kPrimaryColor),
          hintText: S.of(context).hFullName,
          border: InputBorder.none,
        ),
        initialValue: accessController.fullName,
        onSaved: (hFullName) => accessController.fullName = hFullName!,
        validator: (value) {
          if (value!.trim().length < 6) {
            return S.of(context).eValidatoCharacters(6);
          }
          return null;
        },
      ),
    );
  }
}
