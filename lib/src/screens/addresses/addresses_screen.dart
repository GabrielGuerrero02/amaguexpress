import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/models/address_model.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/src/screens/address/address_screen.dart';
import 'package:amaguexpress/src/screens/addresses/addresses_controller.dart';
import 'package:amaguexpress/src/screens/addresses/widget/address_dismissible.dart';
import 'package:amaguexpress/src/widgets/secondary_button.dart';
import 'package:provider/provider.dart';

class AddressesScreen extends StatelessWidget {
  AddressesScreen({super.key});

  final pref = PreferencesProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kPrimaryColor, // Usa tu color primario
          title: Text(S.of(context).tAddresses)),
      body: ChangeNotifierProvider<AddressesController>.value(
        value: AddressesController(),
        child: Consumer<AddressesController>(
          builder: (context, addressesController, child) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Visibility(
                  visible: addressesController.inAsyncCall,
                  child: const LinearProgressIndicator()),
              Expanded(
                  child: ListView.builder(
                itemCount: addressesController.addresses.length,
                itemBuilder: (context, index) => AddressDismissible(
                    addressesController,
                    address: addressesController.addresses[index]),
              )),
              SecondaryButton(
                color: Theme.of(context).colorScheme.secondary,
                text: S.of(context).lNewAddress,
                onPressed: () {
                  AddressModel address = AddressModel(
                      location: Location(x: klatitudeMap, y: klongitudeMap));
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AddressScreen(address: address)));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
