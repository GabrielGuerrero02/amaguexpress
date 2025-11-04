import 'package:amaguexpress/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/src/screens/cart/cart_controller.dart';
import 'package:amaguexpress/src/screens/cart/widget/cart_body.dart';
import 'package:amaguexpress/src/screens/cart_summary/cart_summary_screen.dart';
import 'package:amaguexpress/src/screens/login/login_screen.dart';
import 'package:amaguexpress/src/widgets/image_is_empty.dart';
//import 'package:amaguexpress/src/widgets/secondary_button.dart';
//import 'package:amaguexpress/src/widgets/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:amaguexpress/constants/constants.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

  final pref = PreferencesProvider();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CartController>.value(
      value: CartController(),
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: kPrimaryColor, // Usa tu color primario
            title: Text(S.of(context).tMyOrder)),
        body: Consumer<CartController>(
          builder: (context, cartController, child) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              cartController.products.isEmpty
                  ? const ImageIsEmpty('assets/screen/cart.png', message: '')
                  : Expanded(
                      child: CartBody(products: cartController.products)),
              cartController.products.isEmpty
                  ? Container()
                  : PrimaryButton(
                      text: S.of(context).bContinue,
                      color: kPrimaryColor, // <-- agrega esta línea
                      onPressed: () {
                        if (cartController.products.length <= 0) return;
                        FocusScope.of(context).requestFocus(FocusNode());
                        if (pref.isAuth) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CartSummaryScreen()));
                        } else {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                              (Route<dynamic> route) {
                            return false;
                          });
                        }
                      },
                    )
            ],
          ),
        ),
      ),
    );
  }
}
