import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/common/status_label.dart';
import 'package:amaguexpress/src/screens/order/order_controller.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';

class FloatingHead extends StatelessWidget {
  const FloatingHead({
    super.key,
    required this.orderController,
  });

  final OrderController orderController;

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
              onTap: orderController.centerMap,
              child: ClipOval(
                  child: AvatarImage(
                      image: orderController.order.deliveryman!.image)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${S.of(context).lOrderBy}: ${orderController.order.deliveryman!.fullName}',
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(color: cs.onSurface),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    statusOrderLabel(
                      orderController.order.status,
                      orderController.order.store.company.type,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
