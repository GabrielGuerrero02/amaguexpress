import 'package:flutter/material.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/manager/requests/requests_controller.dart';
import 'package:amaguexpress/src/screens/manager/requests/widget/content_requests.dart';
import 'package:amaguexpress/src/widgets/drawer_menu.dart';
import 'package:provider/provider.dart';
import 'package:amaguexpress/constants/constants.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestsController = Provider.of<RequestsController>(context);
    return Scaffold(
      drawer: DraweMenu(),
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: requestsController.currentScreen == 0
            ? Text(S.of(context).tRequests)
            : Text(S.of(context).tRequestsHistory),
      ),
      body: ContentRequests(requestsController: requestsController),
      bottomNavigationBar: const _Navigation(),
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation();

  @override
  Widget build(BuildContext context) {
    final requestsController = Provider.of<RequestsController>(context);
    return BottomNavigationBar(
      currentIndex: requestsController.currentScreen,
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.electric_bike),
            label: S.of(context).tRequests),
        BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            label: S.of(context).tRequestsHistory),
      ],
      onTap: (i) {
        requestsController.currentScreen = i;
        if (i == 1) {
          requestsController.selectedDay = DateTime.now();
        } else {
          requestsController.loadRequests();
        }
      },
    );
  }
}
