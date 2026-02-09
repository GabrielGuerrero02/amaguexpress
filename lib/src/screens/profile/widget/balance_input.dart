import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';

class BalanceInput extends StatelessWidget {
  BalanceInput(
    this.balance, {
    super.key,
  });

  final double balance;
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    textEditingController.text = balance.toStringAsFixed(kCoinDecimals);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.4),
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
      child: TextField(
        controller: textEditingController,
        readOnly: true,
        autofocus: true,
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.only(
                left: kDefaultPadding * 0.5, top: kDefaultPadding * 0.5),
            labelText: 'Balance',
            prefixIcon:
                const Icon(Icons.price_check_outlined, color: kPrimaryColor),
            border: InputBorder.none,
            hintTextDirection: TextDirection.rtl,
            helperText: S.of(context).lHBalanceValid),
      ),
    );
  }
}
