import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/petition_controller.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/widget/button_collect_float_head.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/widget/button_deliver_float_head.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';
import 'package:amaguexpress/constants/constants.dart';

class FloatingHead extends StatelessWidget {
  const FloatingHead({
    super.key,
    required this.petitionController,
  });

  final PetitionController petitionController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(20),
        height: 70,
        decoration: BoxDecoration(
          color: isDark ? cs.surface : Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          border: Border.all(
            color: kPrimaryColor.withOpacity(isDark ? 0.45 : 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            GestureDetector(
              onTap: petitionController.centerMap,
              child: ClipOval(
                  child: AvatarImage(
                      image: petitionController.petition.user.image)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    petitionController.petition.user.fullName,
                    style: TextStyle(color: cs.onSurface),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    petitionController.petition.store.name,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            _buttonFloatHead(petitionController)
          ],
        ),
      ),
    );
  }

  Widget _buttonFloatHead(PetitionController petitionController) {
    switch (petitionController.petition.status) {
      case StatusOrder.assigned:
        return ButtonCollectFloatHead(petitionController: petitionController);
      case StatusOrder.taken:
        return ButtonDeliverFloatHead(petitionController: petitionController);
      default:
        return Container();
    }
  }
}
