import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/manager/product/product_controller.dart';

class DescriptionInput extends StatelessWidget {
  const DescriptionInput({
    super.key,
    required this.productController,
  });

  final ProductController productController;

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
        maxLines: 4,
        minLines: 1,
        keyboardType: TextInputType.streetAddress,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          icon: const Icon(Icons.description_outlined, color: kPrimaryColor),
          hintText: S.of(context).hProductDescription,
          border: InputBorder.none,
        ),
        initialValue: productController.companyProduct.description,
        onSaved: (description) =>
            productController.companyProduct.description = description!,
        validator: (value) {
          if (value!.trim().length < 10) {
            return S.of(context).eValidatoCharacters(10);
          }
          return null;
        },
      ),
    );
  }
}
