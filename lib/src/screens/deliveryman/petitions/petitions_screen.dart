import 'package:flutter/material.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/deliveryman/petitions/petitions_controller.dart';
import 'package:amaguexpress/src/screens/deliveryman/petitions/widget/button_ofline.dart';
import 'package:amaguexpress/src/screens/deliveryman/petitions/widget/button_online.dart';
import 'package:amaguexpress/src/screens/deliveryman/petitions/widget/content_petitions.dart';
import 'package:amaguexpress/src/widgets/drawer_menu.dart';
import 'package:provider/provider.dart';
import 'package:amaguexpress/constants/constants.dart';

class PetitionsScreen extends StatelessWidget {
  const PetitionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final petitionsController = Provider.of<PetitionsController>(context);
    return Scaffold(
      drawer: DraweMenu(),
      appBar: AppBar(
        backgroundColor: kPrimaryColor, // Usa tu color primario
        title: petitionsController.currentScreen == 0
            ? Text(S.of(context).tPetitions)
            : Text(S.of(context).tPetitionsHistory),
        actions: [
          _buttonAppBar(petitionsController),
        ],
      ),
      body: ContentPetitions(petitionsController: petitionsController),
      bottomNavigationBar: const _Navigation(),
    );
  }

  Widget _buttonAppBar(PetitionsController petitionsController) {
    if (petitionsController.isOnline) {
      return ButtonOnline(petitionsController: petitionsController);
    }
    return ButtonOfline(petitionsController: petitionsController);
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation();

  @override
  Widget build(BuildContext context) {
    final petitionsController = Provider.of<PetitionsController>(context);
    return BottomNavigationBar(
      currentIndex: petitionsController.currentScreen,
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.electric_bike),
            label: S.of(context).tPetitions),
        BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            label: S.of(context).tPetitionsHistory),
      ],
      onTap: (i) {
        petitionsController.currentScreen = i;
        if (i == 1) {
          petitionsController.selectedDay = DateTime.now();
        } else {
          petitionsController.loadPetitions();
        }
      },
    );
  }
}
