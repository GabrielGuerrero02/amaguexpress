import 'package:flutter/material.dart';
import 'package:amaguexpress/src/models/petition_model.dart';

class FloatingButtonWhatsapp extends StatelessWidget {
  const FloatingButtonWhatsapp({
    super.key,
    required this.petition,
  });

  final PetitionModel petition;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
