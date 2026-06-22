import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/src/models/chat_model.dart';
import 'package:amaguexpress/src/screens/chat/chat_screen.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/petition_controller.dart';
import 'package:amaguexpress/src/screens/deliveryman/petitions/petitions_controller.dart';
import 'package:amaguexpress/src/widgets/circular_button.dart';
import 'package:provider/provider.dart';

class FloatingButtonWhatsapp extends StatelessWidget {
  const FloatingButtonWhatsapp({
    super.key,
    required this.petitionController,
  });

  final PetitionController petitionController;

  @override
  Widget build(BuildContext context) {
    final petition = petitionController.petition;

    final canChatClient = petition.status >= StatusOrder.assigned &&
        petition.status <= StatusOrder.taken;

    if (!canChatClient) return const SizedBox.shrink();

    return Positioned(
      top: 190,
      right: kDefaultPadding,
      child: CircularButton(
        icon: const Icon(
          Icons.chat_bubble_outline,
          color: kPrimaryColor,
          size: 38,
        ),
        onPressed: () => _goToChatScreen(context),
      ),
    );
  }

  void _goToChatScreen(BuildContext context) {
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
            label: 'Cliente',
            imageCompany: petitionController.petition.store.company.image,
            channel: 'client_deliveryman',
          ),
          myRol: TypesRol.deliveryman,
        ),
      ),
    );
  }
}
