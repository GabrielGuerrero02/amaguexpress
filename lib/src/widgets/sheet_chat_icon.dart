import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';

class SheetChatIcon extends StatelessWidget {
  const SheetChatIcon({
    super.key,
    required this.notifications,
    required this.goToChatScreen,
  });

  final int notifications;
  final Function goToChatScreen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => goToChatScreen(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chat_outlined,
              color: kPrimaryColor,
              size: 33,
            ),
            onPressed: () => goToChatScreen(context),
          ),
          if (notifications > 0)
            Positioned(
              top: -2,
              right: 0,
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
}
