import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';

class MoneyInput extends StatelessWidget {
  MoneyInput(
    this.money, {
    super.key,
  });

  final double money;
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    textEditingController.text = money.toStringAsFixed(kCoinDecimals);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.4),
      margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.5),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F1F1F)
            : const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label arriba (compacto)
          Padding(
            padding: const EdgeInsets.only(
              left: kDefaultPadding * 0.5,
              top: kDefaultPadding * 0.35,
            ),
            child: Text(
              S.of(context).lTMoneyValid,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFB7BFCC) : const Color(0xFF616161),
              ),
            ),
          ),

          // Campo
          TextField(
            controller: textEditingController,
            readOnly: true,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.only(
                left: kDefaultPadding * 0.5,
                top: kDefaultPadding * 0.25,
                bottom: kDefaultPadding * 0.25,
              ),
              prefixIcon:
                  Icon(Icons.price_check_outlined, color: kPrimaryColor),
              border: InputBorder.none,
            ),
          ),

          // Helper abajo (compacto)
          Padding(
            padding: const EdgeInsets.only(
              left: kDefaultPadding * 0.5,
              right: kDefaultPadding * 0.5,
              bottom: kDefaultPadding * 0.3,
            ),
            child: Text(
              S.of(context).lHMoneyValid,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFB7BFCC) : const Color(0xFF757575),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
