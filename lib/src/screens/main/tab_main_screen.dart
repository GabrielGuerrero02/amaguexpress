import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/code_error_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/src/screens/main/tab1_controller.dart';
import 'package:amaguexpress/src/screens/main/tab1_screen.dart';
import 'package:amaguexpress/src/screens/main/tab2_controller.dart';
import 'package:amaguexpress/src/screens/main/tab2_screen.dart';
import 'package:amaguexpress/src/screens/main/tab_main_controller.dart';
import 'package:amaguexpress/src/screens/main/widget/icon_order.dart';
import 'package:amaguexpress/src/screens/welcome/welcome_screen.dart';
import 'package:amaguexpress/src/widgets/address_dropdown/address_dropdown_controller.dart';
import 'package:amaguexpress/src/widgets/drawer_menu.dart';
import 'package:amaguexpress/src/widgets/icon_cart/icon_cart.dart';
import 'package:provider/provider.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/src/models/address_model.dart';
import 'package:amaguexpress/src/provider/db_provider.dart';

class TabMainScreen extends StatelessWidget {
  const TabMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tab1Controller = Provider.of<Tab1Controller>(context);
    final tabManController = Provider.of<TabManController>(context);
    Provider.of<AddressDropdownController>(context);
    return Scaffold(
      drawer: DraweMenu(),
      appBar: AppBar(
          backgroundColor: kPrimaryColor, // Usa tu color primario
          title: tabManController.currentScreen == 0
              ? SelectedAddress(tab1Controller: tab1Controller)
              : Text(S.of(context).tAppBarOrders),
          actions: [
            if (tabManController.currentScreen == 1)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  Provider.of<Tab2Controller>(context, listen: false)
                      .loadOrders();
                },
              ),
            const IconCart(),
          ]),
      body: Stack(
        children: [
          _Screens(tabManController),
          if (tabManController.currentScreen == 0)
            FutureBuilder<AddressModel?>(
              future: DBProvider.db.loadAddress(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.data != null) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.location_on_outlined,
                              color: Colors.black87),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Aquí arriba selecciona tu ubicación para ver las tiendas y productos disponibles en tu zona.',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: const _Navigation(),
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation();

  @override
  Widget build(BuildContext context) {
    final tabManController = Provider.of<TabManController>(context);
    return BottomNavigationBar(
      currentIndex: tabManController.currentScreen,
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.store), label: S.of(context).tab1),
        BottomNavigationBarItem(
            icon: const IconOrder(), label: S.of(context).tab2)
      ],
      onTap: (i) {
        tabManController.currentScreen = i;
        if (i == 1) {
          Provider.of<Tab2Controller>(context, listen: false).loadOrders();
        } else if (i == 0) {
          Provider.of<Tab1Controller>(context, listen: false).load();
        }
      },
    );
  }
}

class _Screens extends StatefulWidget {
  const _Screens(this.tabManController);

  final TabManController tabManController;

  @override
  State<_Screens> createState() => _ScreensState();
}

class _ScreensState extends State<_Screens> with WidgetsBindingObserver {
  final pref = PreferencesProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => validateSession());
  }

  validateSession() async {
    Provider.of<AddressDropdownController>(context, listen: false)
        .loadAddress();
    final navigator = Navigator.of(context);
    final codeError = await widget.tabManController.checkSession();
    if (codeError == CodeError.unauthorized && !pref.isGuest) {
      PreferencesProvider().clean();
      navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (Route<dynamic> route) {
        return false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        validateSession();
        break;
      case AppLifecycleState.paused:
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: widget.tabManController.pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        Tab1Screen(),
        Tab2Screen(),
      ],
    );
  }
}
