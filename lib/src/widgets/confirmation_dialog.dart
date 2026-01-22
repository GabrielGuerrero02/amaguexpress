import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog(this.message,
      {super.key,
      required this.onPressedOk,
      this.onPressedCancell,
      this.iconOk,
      this.labelOk,
      this.labelCancel,
      this.backgroundColor = kPrimaryColor,
      this.showButtonCancell = true});

  final String message;
  final Icon? iconOk;
  final String? labelOk;
  final String? labelCancel;
  final Function onPressedOk;
  final bool showButtonCancell;
  final Function? onPressedCancell;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(kDefaultPadding * 1.6),
      content: Text(message),
      actions: [
        !showButtonCancell
            ? Container()
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  backgroundColor: const Color.fromARGB(255, 67, 65, 65),
                  side: const BorderSide(
                      color: Color.fromARGB(255, 77, 77, 77), width: 1),
                ),
                onPressed: () {
                  if (onPressedCancell == null) {
                    Navigator.of(context).pop();
                  } else {
                    onPressedCancell!();
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.reply_outlined),
                    const SizedBox(width: kDefaultPadding * .5),
                    Text(labelCancel ?? S.of(context).bCancel),
                    const SizedBox(width: kDefaultPadding * .5),
                  ],
                ),
              ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor, foregroundColor: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
            onPressedOk();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconOk ?? const Icon(Icons.save_outlined),
              const SizedBox(width: kDefaultPadding * .5),
              Text(labelOk ?? S.of(context).bSaveChanges),
              const SizedBox(width: kDefaultPadding * .5),
            ],
          ),
        )
      ],
    );
  }
}
