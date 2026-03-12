import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/models/address_model.dart';
import 'package:amaguexpress/src/provider/db_provider.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/src/provider/push_provider.dart';
import 'package:amaguexpress/src/screens/cart_summary/cart_summary_controller.dart';
import 'package:amaguexpress/src/screens/deliveryman/petitions/petitions_controller.dart';
import 'package:amaguexpress/src/screens/deliveryman/petitions/petitions_screen.dart';
import 'package:amaguexpress/src/screens/login/login_controller.dart';
import 'package:amaguexpress/src/screens/main/tab1_controller.dart';
import 'package:amaguexpress/src/screens/main/tab2_controller.dart';
import 'package:amaguexpress/src/screens/main/tab_main_controller.dart';
import 'package:amaguexpress/src/screens/main/tab_main_screen.dart';
import 'package:amaguexpress/src/screens/manager/enrollment/enrollment_controller.dart';
import 'package:amaguexpress/src/screens/manager/product/product_controller.dart';
import 'package:amaguexpress/src/screens/manager/requests/requests_controller.dart';
import 'package:amaguexpress/src/screens/manager/requests/requests_screen.dart';
import 'package:amaguexpress/src/screens/store/store_controller.dart';
import 'package:amaguexpress/src/screens/welcome/welcome_screen.dart';
import 'package:amaguexpress/src/widgets/address_dropdown/address_dropdown_controller.dart';
import 'package:amaguexpress/src/widgets/category_dropdown/category_dropdown_controller.dart';
import 'package:amaguexpress/src/widgets/icon_cart/icon_cart_controller.dart';
import 'package:amaguexpress/src/widgets/payment_dropdown/payment_dropdown_controller.dart';
import 'package:amaguexpress/theme.dart';
import 'package:provider/provider.dart';
import 'package:amaguexpress/src/screens/chatbot/chatbot_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Override de certificados SOLO en modo debug
  assert(() {
    HttpOverrides.global = MyHttpOverrides();
    return true;
  }());

  await Firebase.initializeApp();
  await PreferencesProvider().init();
  await PushProvider().init();
  final AddressModel? address = await DBProvider.db.loadAddress();
  final pref = PreferencesProvider();
  //Stripe.publishableKey = kStripePublishableKey;
  runApp(MyApp(address: address, pref: pref));
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  final AddressModel? address;
  final PreferencesProvider pref;

  const MyApp({super.key, required this.address, required this.pref});

  @override
  Widget build(BuildContext context) {
    String initialRoute = pref.isAuth
        ? 'tabs'
        : address == null
            ? 'welcome'
            : 'tabs';
    if (pref.user.roles.contains(TypesRol.deliveryman)) {
      initialRoute = 'petitions';
    } else if (pref.user.roles.contains(TypesRol.manager)) {
      initialRoute = 'requests';
    }
    pref.locale = Platform.localeName;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IconCartController()),
        ChangeNotifierProvider(create: (_) => StoreController()),
        ChangeNotifierProvider(create: (_) => TabManController()),
        ChangeNotifierProvider(create: (_) => Tab1Controller()),
        ChangeNotifierProvider(create: (_) => Tab2Controller()),
        ChangeNotifierProvider(create: (_) => AddressDropdownController()),
        ChangeNotifierProvider(create: (_) => PaymentDropdownController()),
        ChangeNotifierProvider(create: (_) => CartSummaryController()),
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => PetitionsController()),
        ChangeNotifierProvider(create: (_) => RequestsController()),
        ChangeNotifierProvider(create: (_) => CategoryDropdownController()),
        ChangeNotifierProvider(create: (_) => EnrollmentController()),
        ChangeNotifierProvider(create: (_) => ProductController()),
      ],
      child: MaterialApp(
        title: kNameApp,
        debugShowCheckedModeBanner: false,
        initialRoute: initialRoute,
        routes: {
          'welcome': (BuildContext context) => const WelcomeScreen(),
          'tabs': (BuildContext context) => const TabMainScreen(),
          'petitions': (BuildContext context) => const PetitionsScreen(),
          'requests': (BuildContext context) => const RequestsScreen(),
          '/chatbot': (context) => const ChatbotScreen(),
        },
        theme: lightThemeData(context),
        darkTheme: darkThemeData(context),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          S.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
      ),
    );
  }
}
