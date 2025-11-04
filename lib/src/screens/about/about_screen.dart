import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/common/launch.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/src/widgets/primary_button.dart';
import 'package:amaguexpress/src/widgets/secondary_button.dart';

class AboutScreen extends StatelessWidget {
  AboutScreen({super.key});

  final pref = PreferencesProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kPrimaryColor, // Usa tu color primario
          title: Text(S.of(context).tAbout)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Column(
                children: [
                  const SizedBox(height: kDefaultPadding * 3),
                  GestureDetector(
                    onTap: () {
                      goToUrl('http://www.amaguexpress.com');
                    },
                    child: Image.asset("assets/screen/icon.png", height: 200),
                  ),
                  const SizedBox(height: kDefaultPadding * 3),
                  PrimaryButton(
                    icon: Icons.web_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                    text: 'Sitio Web Principal',
                    onPressed: () => goToUrl('http://www.amaguexpress.com'),
                  ),
                  const SizedBox(height: kDefaultPadding),
                  const Text(
                    "Este Software es propiedad de AmaguExpress Delivery, para mayor informaciòn visite el sitio web principal, o los terminos y condiciones.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kDefaultPadding),
                  SecondaryButton(
                    color: Theme.of(context).colorScheme.secondary,
                    text: 'Terminos y Condiciones',
                    onPressed: () =>
                        goToUrl('https://www.amaguexpress.com/terminos.html'),
                  ),
                  const SizedBox(height: kDefaultPadding),
                  SecondaryButton(
                    color: Theme.of(context).colorScheme.secondary,
                    text: 'Politica de Privacidad',
                    onPressed: () =>
                        goToUrl('https://www.amaguexpress.com/privacidad.html'),
                  )
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
