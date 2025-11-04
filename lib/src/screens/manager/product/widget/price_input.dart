import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/common/validator.dart';
import 'package:amaguexpress/src/screens/manager/product/product_controller.dart';

class PriceInput extends StatelessWidget {
  const PriceInput({
    super.key,
    required this.productController,
  });

  final ProductController productController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.75),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black, // Borde negro
          width: 1, // Delgado
        ),
      ),
      child: TextFormField(
        keyboardType: TextInputType.number,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          icon: const Icon(Icons.price_check_outlined, color: kPrimaryColor),
          hintText: S.of(context).lPrice,
          border: InputBorder.none,
        ),
        initialValue: productController.companyProduct.price
            .toStringAsFixed(kCoinDecimals),
        onSaved: (price) {
          price = price!.trim();
          price = price.replaceFirst(',', '.');
          productController.companyProduct.price = double.parse(price);
        },
        validator: (value) => validatePrice(context, value!),
      ),
    );
  }
}
