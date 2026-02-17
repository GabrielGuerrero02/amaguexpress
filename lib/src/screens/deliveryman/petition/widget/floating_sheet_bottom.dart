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
                    child: _chatClient(context),
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
                    child: _callClient(context),
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

  Widget _callClient(BuildContext context) {
    if (petitionController.petition.status >= StatusOrder.assigned &&
        petitionController.petition.status <= StatusOrder.taken) {
      return _floatingAction(
        context,
        label: 'Llamar',
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          onPressed: () => call(petitionController.petition.user.phone),
          icon: const Icon(
            Icons.quick_contacts_dialer_outlined,
            color: kPrimaryColor,
            size: 30,
          ),
        ),
      );
    }
    return Container();
  }

  Widget _chatClient(BuildContext context) {
    if (petitionController.petition.status >= StatusOrder.assigned &&
        petitionController.petition.status <= StatusOrder.taken) {
      return _floatingAction(
        context,
        label: petitionController.petition.user.fullName.isNotEmpty
            ? petitionController.petition.user.fullName
            : S.of(context).lClient,
        child: IconChat(petitionController),
      );
    }
    return Container();
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
