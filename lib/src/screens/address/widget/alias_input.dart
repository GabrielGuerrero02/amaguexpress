import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/address/address_controller.dart';

class AliasInput extends StatelessWidget {
  const AliasInput({
    super.key,
    required this.addressController,
  });

  final AddressController addressController;

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
          icon: const Icon(Icons.place_outlined, color: kPrimaryColor),
          hintText: S.of(context).hAlias,
          border: InputBorder.none,
        ),
        initialValue: addressController.address.alias,
        onSaved: (alias) => addressController.address.alias = alias!,
        validator: (value) {
          if (value!.trim().length < 2) {
            return S.of(context).eValidatoCharacters(2);
          }
          return null;
        },
      ),
    );
  }
}
