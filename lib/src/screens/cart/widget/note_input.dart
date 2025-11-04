import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/models/product_model.dart';
import 'package:amaguexpress/src/screens/cart/cart_controller.dart';

class NoteInput extends StatelessWidget {
  const NoteInput({
    super.key,
    required this.product,
    required this.cartController,
  });

  final ProductModel product;
  final CartController cartController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding * 0.75,
            ),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.black, // Borde negro
                width: 1, // Delgado
              ),
            ),
            child: TextFormField(
              onChanged: (value) {
                product.note = value;
                cartController.updateProduct(product);
              },
              maxLines: 4,
              maxLength: 102,
              minLines: 1,
              keyboardType: TextInputType.streetAddress,
              decoration: InputDecoration(
                icon: const Icon(Icons.edit_note_sharp, color: kPrimaryColor),
                hintText: S.of(context).hNoteProdcut,
                border: InputBorder.none,
              ),
              initialValue: product.note,
              onEditingComplete: () => _saveNote(context),
            ),
          ),
        ),
        // const SizedBox(width: kDefaultPadding * .05),
        // IconButton(
        //     onPressed: () => _saveNote(context),
        //     icon: const Icon(Icons.save_outlined, color: kPrimaryColor)),
      ],
    );
  }

  _saveNote(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
    cartController.updateProduct(product);
  }
}
