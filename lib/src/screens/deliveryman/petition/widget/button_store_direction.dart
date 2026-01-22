import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/common/launch.dart';
import 'package:amaguexpress/src/models/petition_model.dart';

class ButtonStoreDirection extends StatelessWidget {
  const ButtonStoreDirection({
    super.key,
    required this.petition,
  });

  final PetitionModel petition;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0))),
      label: Text(
        S.of(context).bRouteStore,
        style: const TextStyle(color: kPrimaryColor),
      ),
      icon: const Icon(
        Icons.travel_explore,
        color: kPrimaryColor,
        size: 30,
      ),
      onPressed: () {
        openMapDirections(petition.start.x, petition.start.y);
      },
    );
  }
}
