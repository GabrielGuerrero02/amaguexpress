import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
//import 'package:amaguexpress/src/bloc/location_bloc.dart';
import 'package:amaguexpress/src/common/launch.dart';
//import 'package:amaguexpress/src/models/address_model.dart';
//import 'package:amaguexpress/src/screens/address/address_screen.dart';
import 'package:amaguexpress/src/screens/login/login_screen.dart';
import 'package:amaguexpress/src/widgets/primary_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: kDefaultPadding * 3.2),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image(
                image: AssetImage(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/screen/welcome_dark.png'
                      : 'assets/screen/welcome.png',
                ),
              ),
            ),
            const SizedBox(height: kDefaultPadding * 2.2),
            Text(S.of(context).tWelcome,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: kDefaultPadding * 2.2),
            //PrimaryButton(
            //    text: S.of(context).bEstablishLocation,
            //    onPressed: _goToAddressScreen),
            //const SizedBox(height: 20.0),
            //Center(child: Text(S.of(context).mEither)),
            //const SizedBox(height: 20.0),
            PrimaryButton(
              text: 'Iniciar sesión',
              onPressed: _goToSigninScreen,
            ),
            const SizedBox(height: kDefaultPadding),
            const Text(
              'Explora tiendas y productos sin crear cuenta. Inicia sesión solo cuando quieras comprar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kDefaultPadding),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _continueAsGuest,
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.grey.shade500,
                    foregroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.grey.shade700,
                    ),
                  ),
                  child: const Text('Explorar como invitado'),
                ),
              ),
            ),
            const SizedBox(height: kDefaultPadding * 3.2),
            const Text(
                'Al usar nuestro producto aceptas los terminos, condiciones y politicas de privacidad\nV: $kVersionn\nCreado por AmaguExpress',
                textScaler: TextScaler.linear(0.8),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => goToUrl('http://www.amaguexpress.com'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Politica de Privacidad',
                style: TextStyle(color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 0),
            TextButton(
              onPressed: () => goToUrl('http://www.amaguexpress.com'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Terminos y Condiciones',
                style: TextStyle(color: Colors.indigo),
              ),
            ),
            const SizedBox(height: kDefaultPadding * 0.14),
          ],
        ),
      ),
    ));
  }

  //_goToAddressScreen() async {
  //  LocationBloc().determinePosition();
  //  AddressModel address =
  //      AddressModel(location: Location(x: klatitudeMap, y: klongitudeMap));
  //  Navigator.of(context).push(
  //    MaterialPageRoute(
  //      builder: (context) => AddressScreen(address: address),
  //    ),
  //  );
  //}

  _goToSigninScreen() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  _continueAsGuest() async {
    Navigator.of(context).pushReplacementNamed('tabs');
  }
}
