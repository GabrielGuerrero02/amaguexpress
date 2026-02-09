import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/chat/chat_controller.dart';

class ChatInput extends StatelessWidget {
  final ChatController chatController;

  const ChatInput(
    this.chatController, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
          bottom: kDefaultPadding * .6, left: kDefaultPadding),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding * 0.75),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1F1F1F)
                    : const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black, // Borde negro
                  width: 1, // Delgado
                ),
              ),
              child: TextFormField(
                controller: chatController.textControlle,
                maxLines: 4,
                minLines: 1,
                keyboardType: TextInputType.streetAddress,
                decoration: InputDecoration(
                  icon: const Icon(Icons.edit_note_sharp, color: kPrimaryColor),
                  hintText: S.of(context).hChat,
                  border: InputBorder.none,
                ),
                onEditingComplete: () => _sendMessage(context),
              ),
            ),
          ),
          const SizedBox(width: kDefaultPadding * .05),
          IconButton(
              onPressed: () => _sendMessage(context),
              icon: const Icon(Icons.send, color: kPrimaryColor)),
        ],
      ),
    );
  }

  _sendMessage(BuildContext context) {
    chatController.sendText();
  }
}
