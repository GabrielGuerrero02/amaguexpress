import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/models/chat_model.dart';
import 'package:amaguexpress/src/screens/chat/chat_screen.dart';
import 'package:amaguexpress/src/screens/main/tab2_controller.dart';
import 'package:amaguexpress/src/screens/order/order_controller.dart';
import 'package:amaguexpress/src/screens/order/widget/info_product.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';
import 'package:amaguexpress/src/widgets/sheet_chat_icon.dart';
import 'package:provider/provider.dart';

class FloatingSheetBottom extends StatelessWidget {
  final OrderController orderController;

  const FloatingSheetBottom({super.key, required this.orderController});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.3,
      maxChildSize: 1,
      snap: true,
      snapSizes: const [0.7, 1],
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.only(top: 0, right: 10, left: 10, bottom: 10),
        color: isDark ? cs.surface : Colors.white,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: SizedBox(
                  width: 60,
                  child: Divider(
                    thickness: 5,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  SizedBox(
                    width: 80,
                    child: orderController.order.status >=
                                StatusOrder.assigned &&
                            orderController.order.status <= StatusOrder.taken
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? cs.surfaceContainerHighest
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: kPrimaryColor.withOpacity(
                                  isDark ? 0.35 : 0.25,
                                ),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isDark ? 0.35 : 0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconChat(orderController),
                                const SizedBox(height: 2),
                                Text(
                                  orderController.order.deliveryman?.fullName ??
                                      S.of(context).lDeliveryman,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                  ),
                  SizedBox(
                    height: 70,
                    child: ClipOval(
                        child: AvatarImage(
                            image: orderController.order.store.company.image)),
                  ),
                  const SizedBox(width: 80),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Icon(
                      orderController.order.payment == TypesPayment.money
                          ? Icons.credit_score_outlined
                          : Icons.payments_outlined,
                      color: kErrorColor),
                  const SizedBox(width: kDefaultPadding * 0.5),
                  Text(
                      orderController.order.payment == TypesPayment.money
                          ? S.of(context).lPayMoney
                          : S.of(context).lPayCash,
                      style: const TextStyle(color: kErrorColor)),
                  Expanded(child: Container()),
                  Expanded(child: Container()),
                  Text(
                    '${S.of(context).lTotal} ${orderController.order.total.toStringAsFixed(kCoinDecimals)} $kCoin',
                    style: TextStyle(color: cs.onSurface),
                  ),
                  const SizedBox(width: 10)
                ],
              ),
              const SizedBox(height: 10),
              _OrderDetailTimeInfo(
                status: orderController.order.status,
                preparationTimeMinutes:
                    orderController.order.preparationTimeMinutes,
                estimatedReadyAt: orderController.order.estimatedReadyAt,
              ),
              const SizedBox(height: 10),
              InfoProduct(order: orderController.order),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailTimeInfo extends StatelessWidget {
  final int status;
  final int? preparationTimeMinutes;
  final DateTime? estimatedReadyAt;

  const _OrderDetailTimeInfo({
    required this.status,
    required this.preparationTimeMinutes,
    required this.estimatedReadyAt,
  });

  String? _timeLabel(DateTime now) {
    if (status == StatusOrder.pendingStoreConfirmation) {
      return '⏳ Esperando aprobación de la tienda';
    }

    const deliveryEstimate = 10;

    if (estimatedReadyAt != null) {
      final remainingSeconds = estimatedReadyAt!.difference(now).inSeconds;
      final remainingPreparation =
          remainingSeconds <= 0 ? 0 : ((remainingSeconds + 59) ~/ 60);

      if (remainingPreparation <= 0) {
        return '⏱ Entrega estimada: $deliveryEstimate min';
      }

      return '⏱ Entrega estimada: ${remainingPreparation + deliveryEstimate} min';
    }

    if (preparationTimeMinutes == null || preparationTimeMinutes! <= 0) {
      return null;
    }

    return '⏱ Entrega estimada: ${preparationTimeMinutes! + deliveryEstimate} min';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<int>(
      stream: Stream<int>.periodic(
        const Duration(minutes: 1),
        (value) => value,
      ),
      initialData: 0,
      builder: (context, _) {
        final label = _timeLabel(DateTime.now());
        if (label == null) return const SizedBox.shrink();

        return Row(
          children: [
            const Icon(Icons.schedule_outlined, size: 18, color: kPrimaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class IconChat extends StatelessWidget {
  const IconChat(
    this.orderController, {
    super.key,
  });

  final OrderController orderController;

  @override
  Widget build(BuildContext context) {
    return SheetChatIcon(
        notifications: orderController.order.notificationsClient,
        goToChatScreen: _goToChatScreen);
  }

  _goToChatScreen(BuildContext context) {
    orderController.cleanNotificationsClient();
    Provider.of<Tab2Controller>(context, listen: false)
        .cleanNotificationsClient(orderController.order.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatModel: ChatModel(
            orderId: orderController.order.id,
            toUser:
                ToUser.fromJson(orderController.order.deliveryman!.toJson()),
            label: S.of(context).lDeliveryman,
            imageCompany: orderController.order.store.company.image,
          ),
          myRol: TypesRol.client,
        ),
      ),
    );
  }
}
