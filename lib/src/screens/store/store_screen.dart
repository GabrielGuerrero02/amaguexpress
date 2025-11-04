import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/models/company_model.dart';
import 'package:amaguexpress/src/screens/store/store_controller.dart';
import 'package:amaguexpress/src/screens/store/widget/group_product.dart';
import 'package:amaguexpress/src/screens/store/widget/list_product.dart';
import 'package:amaguexpress/src/widgets/icon_cart/icon_cart.dart';
import 'package:amaguexpress/src/widgets/label.dart';
import 'package:amaguexpress/src/widgets/modal_progress_hud.dart';
import 'package:provider/provider.dart';

class StoreScreen extends StatelessWidget {
  final CompanyModel company;

  const StoreScreen(this.company, {super.key});

  @override
  Widget build(BuildContext context) {
    final storeController = Provider.of<StoreController>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor, // Usa tu color primario
        title: Text(company.name),
        actions: const [IconCart()],
      ),
      body: ModalProgressHUD(
        inAsyncCall: storeController.inAsyncCall,
        child: Column(
          children: [
            Row(
              children: [
                Label(S.of(context).tStore, (S.of(context).tTStore)),
                Expanded(child: Container()),
                Text(
                    '${S.of(context).lDeliveryFee} ${storeController.deliveryFee.toStringAsFixed(kCoinDecimals)} $kCoin'),
                const SizedBox(width: kDefaultPadding),
              ],
            ),
            if (storeController.groups.isNotEmpty)
              GroupProduct(storeController: storeController),
            Expanded(child: ListProduct(storeController.products))
          ],
        ),
      ),
    );
  }
}
