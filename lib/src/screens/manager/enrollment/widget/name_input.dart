import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/manager/enrollment/enrollment_controller.dart';

class NameInput extends StatelessWidget {
  const NameInput({
    super.key,
    required this.enrollmentController,
  });

  final EnrollmentController enrollmentController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.75),
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
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          icon: const Icon(Icons.store_outlined, color: kPrimaryColor),
          hintText: S.of(context).hFullName,
          border: InputBorder.none,
        ),
        initialValue: enrollmentController.enrollment.name,
        onSaved: (name) => enrollmentController.enrollment.name = name!.trim(),
        validator: (value) {
          if (value!.trim().length < 5) {
            return S.of(context).eValidatoCharacters(5);
          }
          return null;
        },
      ),
    );
  }
}
