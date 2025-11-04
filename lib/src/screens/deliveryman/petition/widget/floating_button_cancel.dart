import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/petition_controller.dart';
import 'package:amaguexpress/src/screens/deliveryman/petitions/petitions_controller.dart';
import 'package:amaguexpress/src/widgets/circular_button.dart';
import 'package:amaguexpress/src/widgets/confirmation_dialog.dart';
import 'package:provider/provider.dart';

class FloatingButtonCancel extends StatelessWidget {
  const FloatingButtonCancel({
    super.key,
    required this.petitionController,
  });

  final PetitionController petitionController;

  @override
  Widget build(BuildContext context) {
    return petitionController.petition.status == StatusOrder.assigned
        ? Positioned(
            top: 280,
            right: kDefaultPadding,
            child: CircularButton(
              icon: const Icon(Icons.cancel_outlined,
                  color: kErrorColor, size: 40),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ConfirmationDialog(
                    S.of(context).mDCancelOrder(S.of(context).bCancel),
                    labelOk: S.of(context).bCancel,
                    labelCancel: S.of(context).bReturn,
                    backgroundColor: kErrorColor,
                    iconOk: const Icon(Icons.cancel_outlined),
                    onPressedOk: () async {
                      final petitionsController =
                          Provider.of<PetitionsController>(context,
                              listen: false);
                      final navigator = Navigator.of(context);
                      await petitionController.cancel();
                      petitionsController.loadPetitions();
                      navigator.popUntil((route) => route.isFirst);
                    },
                  ),
                );
              },
            ),
          )
        : Container();
  }
}
