import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/src/common/launch.dart';
import 'package:amaguexpress/src/models/petition_model.dart';
import 'package:amaguexpress/src/widgets/circular_button.dart';

class FloatingButtonCall extends StatelessWidget {
  const FloatingButtonCall({
    super.key,
    required this.petition,
  });

  final PetitionModel petition;

  @override
  Widget build(BuildContext context) {
    final canCallStore = petition.status >= StatusOrder.assigned &&
        petition.status <= StatusOrder.taken;

    if (!canCallStore) return Container();

    return Positioned(
      top: 110,
      right: kDefaultPadding,
      child: CircularButton(
        icon: const Icon(Icons.call_outlined, color: kPrimaryColor, size: 40),
        onPressed: () {
          call(petition.user.phone);
        },
      ),
    );
  }
}
