import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
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
    return Positioned(
      top: 200,
      right: kDefaultPadding,
      child: CircularButton(
        icon: const Icon(Icons.call_outlined, color: kPrimaryColor, size: 40),
        onPressed: () {
          call(petition.store.contact);
        },
      ),
    );
  }
}
