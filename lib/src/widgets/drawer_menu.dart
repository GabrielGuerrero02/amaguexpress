import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/src/screens/about/about_screen.dart';
import 'package:amaguexpress/src/screens/addresses/addresses_screen.dart';
import 'package:amaguexpress/src/screens/admin/credit/credit_screen.dart';
import 'package:amaguexpress/src/screens/manager/company/company_screen.dart';
import 'package:amaguexpress/src/screens/manager/enrollment/enrollment_screen.dart';
import 'package:amaguexpress/src/screens/notification/notification_screen.dart';
import 'package:amaguexpress/src/screens/profile/profile_screen.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';

class DraweMenu extends StatelessWidget {
  DraweMenu({super.key});

  final pref = PreferencesProvider();

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                DrawerHeader(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  child: Header(pref),
                ),
                Visibility(
                  visible: pref.user.roles.contains(TypesRol.admin),
                  child: Container(
                    padding: const EdgeInsets.only(left: 15.0),
                    child: ListTile(
                        leading: const Icon(Icons.price_check_outlined,
                            color: kPrimaryColor),
                        title: Text(S.of(context).tTopUpBalance),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CreditScreen()));
                        }),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: ListTile(
                      leading: const Icon(Icons.notification_add_outlined,
                          color: kPrimaryColor),
                      title: Text(S.of(context).tNotifications),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const NotificacionPage()));
                      }),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: ListTile(
                      leading: const Icon(Icons.store_outlined,
                          color: kPrimaryColor),
                      title: Text(S.of(context).tStores),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CompanyScreen()));
                      }),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: ListTile(
                      leading: const Icon(Icons.pin_drop_outlined,
                          color: kPrimaryColor),
                      title: Text(S.of(context).tAddresses),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddressesScreen()));
                      }),
                ),
              ],
            ),
          ),
        ),
        Footer(pref)
      ],
    ));
  }
}

class Header extends StatelessWidget {
  final PreferencesProvider pref;

  const Header(
    this.pref, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CircularPercentIndicator(
          radius: 33.0,
          lineWidth: 3.0,
          percent: 1.0,
          center: AvatarImage(
              width: 60,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
              image: pref.user.image),
          progressColor: kPrimaryColor,
        ),
        const SizedBox(width: kDefaultPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pref.user.fullName,
                textScaler: const TextScaler.linear(1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                pref.user.email,
                textScaler: const TextScaler.linear(0.9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFB7BFCC)
                      : kSecondaryColor,
                ),
              ),
            ],
          ),
        )
      ],
    );
    return Stack(
      children: [
        content,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.blueAccent.withValues(alpha: (0.6 * 255)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
          ),
        ),
      ],
    );
  }
}

class Footer extends StatelessWidget {
  const Footer(
    this.pref, {
    super.key,
  });

  final PreferencesProvider pref;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Visibility(
          visible:
              !pref.user.roles.contains(TypesRol.deliveryman) && !pref.isGuest,
          child: ListTile(
            leading: const Icon(Icons.app_registration_outlined,
                color: kPrimaryColor),
            title: Text(S.of(context).tRegisterStore),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => EnrollmentScreen()));
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.mode_of_travel, color: kPrimaryColor),
          title: Text(S.of(context).tAbout),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AboutScreen()));
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Material(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading:
                  const Icon(Icons.smart_toy_outlined, color: Colors.white),
              title: const Text(
                "Habla con Amagú",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chatbot');
              },
            ),
          ),
        ),
        const Divider(),
        const SizedBox(height: 1),
        const Text(
          'Al usar nuestros servicos tu aceptas nuestros terminos y condiciones\nV: $kVersionn\nCreado por AmaguExpress',
          textScaler: TextScaler.linear(0.72),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
