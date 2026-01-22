import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/src/common/launch.dart';
import 'package:amaguexpress/src/models/petition_model.dart';
import 'package:amaguexpress/src/widgets/circular_button.dart';

class FloatingButtonWhatsapp extends StatelessWidget {
  const FloatingButtonWhatsapp({
    super.key,
    required this.petition,
  });

  final PetitionModel petition;

  @override
  Widget build(BuildContext context) {
    return petition.status == StatusOrder.assigned
        ? Positioned(
            top: 120,
            right: kDefaultPadding,
            child: CircularButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: kPrimaryColor, size: 40),
              onPressed: () {
                sendWhatsapp(petition.store.contact,
                    '${petition.user.fullName}\n${petition.products.join('\n')}');
              },
            ),
          )
        : Container();
  }
}
