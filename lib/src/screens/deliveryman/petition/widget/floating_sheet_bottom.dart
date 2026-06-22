import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/common/launch.dart';
import 'package:amaguexpress/src/models/chat_model.dart';
import 'package:amaguexpress/src/screens/chat/chat_screen.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/petition_controller.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/widget/details_products.dart';
import 'package:amaguexpress/src/screens/deliveryman/petitions/petitions_controller.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';
import 'package:amaguexpress/src/widgets/sheet_chat_icon.dart';
import 'package:provider/provider.dart';

class FloatingSheetBottom extends StatelessWidget {
  final PetitionController petitionController;

  const FloatingSheetBottom({super.key, required this.petitionController});

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
                    child: _chatStore(context),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? cs.surfaceContainerHighest : Colors.white,
                      border: Border.all(
                        color: kPrimaryColor.withOpacity(isDark ? 0.35 : 0.22),
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
                    child: SizedBox(
                      height: 62,
                      width: 62,
                      child: ClipOval(
                        child: AvatarImage(
                          image:
                              petitionController.petition.store.company.image,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: _callStore(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Icon(
                      petitionController.petition.payment == TypesPayment.money
                          ? Icons.credit_score_outlined
                          : Icons.payments_outlined,
                      color: kErrorColor),
                  const SizedBox(width: kDefaultPadding * 0.5),
                  Text(
                      petitionController.petition.payment == TypesPayment.money
                          ? S.of(context).lPayMoney
                          : S.of(context).lPayCash,
                      style: const TextStyle(color: kErrorColor)),
                  Expanded(child: Container()),
                  Text(
                    '${S.of(context).lTotal} ${petitionController.petition.total.toStringAsFixed(kCoinDecimals)} $kCoin',
                    style: TextStyle(color: cs.onSurface),
                  ),
                  const SizedBox(width: 10)
                ],
              ),
              const SizedBox(height: 10),
              _DeliverymanDetailTimeInfo(
                preparationTimeMinutes:
                    petitionController.petition.preparationTimeMinutes,
                estimatedReadyAt: petitionController.petition.estimatedReadyAt,
              ),
              const SizedBox(height: 10),
              DetailsProducts(petition: petitionController.petition),
            ],
          ),
        ),
      ),
    );
  }

  Widget _floatingAction(BuildContext context,
      {required Widget child, required String label}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kPrimaryColor.withOpacity(isDark ? 0.35 : 0.25),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 28,
            width: 28,
            child: FittedBox(
              fit: BoxFit.contain,
              child: child,
            ),
          ),
          const SizedBox(height: 0),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.0,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _callStore(BuildContext context) {
    if (petitionController.petition.status >= StatusOrder.assigned &&
        petitionController.petition.status <= StatusOrder.taken) {
      return _floatingAction(
        context,
        label: 'Llamar tienda',
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          onPressed: () => call(petitionController.petition.store.contact),
          icon: const Icon(
            Icons.storefront_outlined,
            color: kPrimaryColor,
            size: 30,
          ),
        ),
      );
    }
    return Container();
  }

  Widget _chatStore(BuildContext context) {
    final storeUser = petitionController.petition.store.user;

    if (storeUser == null) return Container();

    if (petitionController.petition.status >= StatusOrder.assigned &&
        petitionController.petition.status <= StatusOrder.taken) {
      return _floatingAction(
        context,
        label: 'Chat tienda',
        child: IconStoreChat(petitionController),
      );
    }
    return Container();
  }
}

class _DeliverymanDetailTimeInfo extends StatelessWidget {
  final int? preparationTimeMinutes;
  final DateTime? estimatedReadyAt;

  const _DeliverymanDetailTimeInfo({
    required this.preparationTimeMinutes,
    required this.estimatedReadyAt,
  });

  String? _timeLabel(DateTime now) {
    if (estimatedReadyAt != null) {
      final remainingSeconds = estimatedReadyAt!.difference(now).inSeconds;
      final remainingPreparation =
          remainingSeconds <= 0 ? 0 : ((remainingSeconds + 59) ~/ 60);

      if (remainingPreparation <= 0) {
        return '⏱ Pedido listo para recoger';
      }

      return '⏱ Ir a tienda en $remainingPreparation min';
    }

    if (preparationTimeMinutes == null || preparationTimeMinutes! <= 0) {
      return null;
    }

    return '⏱ Preparación: $preparationTimeMinutes min';
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
    this.petitionController, {
    super.key,
  });

  final PetitionController petitionController;

  @override
  Widget build(BuildContext context) {
    return SheetChatIcon(
        notifications: petitionController.petition.notificationsDeliveryman,
        goToChatScreen: _goToChatScreen);
  }

  _goToChatScreen(BuildContext context) {
    petitionController.cleanNotificationsClient();
    Provider.of<PetitionsController>(context, listen: false)
        .cleanNotificationsDeliveryman(petitionController.petition.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatModel: ChatModel(
            orderId: petitionController.petition.id,
            toUser: ToUser.fromJson(petitionController.petition.user.toJson()),
            label: S.of(context).lClient,
            imageCompany: petitionController.petition.store.company.image,
          ),
          myRol: TypesRol.deliveryman,
        ),
      ),
    );
  }
}

class IconStoreChat extends StatelessWidget {
  const IconStoreChat(
    this.petitionController, {
    super.key,
  });

  final PetitionController petitionController;

  @override
  Widget build(BuildContext context) {
    return SheetChatIcon(
      notifications: 0,
      goToChatScreen: _goToChatScreen,
    );
  }

  _goToChatScreen(BuildContext context) {
    final storeUser = petitionController.petition.store.user;
    if (storeUser == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatModel: ChatModel(
            orderId: petitionController.petition.id,
            toUser: ToUser.fromJson(storeUser.toJson()),
            label: 'Tienda',
            imageCompany: petitionController.petition.store.company.image,
            channel: 'store_deliveryman',
          ),
          myRol: TypesRol.deliveryman,
        ),
      ),
    );
  }
}
