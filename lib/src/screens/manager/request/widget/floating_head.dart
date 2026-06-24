import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/common/launch.dart';
import 'package:amaguexpress/src/models/chat_model.dart';
import 'package:amaguexpress/src/screens/manager/request/request_controller.dart';
import 'package:amaguexpress/src/screens/chat/chat_screen.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';
import 'package:amaguexpress/src/widgets/circular_button.dart';

class FloatingHead extends StatelessWidget {
  const FloatingHead({
    super.key,
    required this.requestController,
  });

  final RequestController requestController;

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
              onTap: requestController.centerMap,
              child: ClipOval(
                  child:
                      AvatarImage(image: requestController.request.user.image)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    requestController.request.user.fullName,
                    style: TextStyle(color: cs.onSurface),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    S.of(context).lClient,
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

class FloatingClientCallButton extends StatelessWidget {
  const FloatingClientCallButton({
    super.key,
    required this.requestController,
  });

  final RequestController requestController;

  @override
  Widget build(BuildContext context) {
    final canCallClient =
        requestController.request.status >= StatusOrder.started &&
            requestController.request.status <= StatusOrder.taken;

    if (!canCallClient) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      right: kDefaultPadding,
      child: CircularButton(
        icon: const Icon(Icons.call_outlined, color: kPrimaryColor, size: 40),
        onPressed: () {
          call(requestController.request.user.phone);
        },
      ),
    );
  }
}

class FloatingClientChatButton extends StatelessWidget {
  const FloatingClientChatButton({
    super.key,
    required this.requestController,
  });

  final RequestController requestController;

  @override
  Widget build(BuildContext context) {
    final canChatClient =
        requestController.request.status >= StatusOrder.started &&
            requestController.request.status <= StatusOrder.taken;

    if (!canChatClient) return const SizedBox.shrink();

    final notifications = requestController.notificationsClientStoreChat;

    return Positioned(
      top: 170,
      right: kDefaultPadding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircularButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: kPrimaryColor,
              size: 38,
            ),
            onPressed: () => _goToClientChat(context),
          ),
          if (notifications > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: const BoxDecoration(
                  color: kErrorColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    notifications > 99 ? '99+' : notifications.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _goToClientChat(BuildContext context) {
    requestController.cleanNotificationsClient();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatModel: ChatModel(
            orderId: requestController.request.id,
            toUser: ToUser.fromJson(requestController.request.user.toJson()),
            label: S.of(context).lClient,
            imageCompany: requestController.request.store.company.image,
            channel: 'client_store',
          ),
          myRol: TypesRol.manager,
        ),
      ),
    );
  }
}
