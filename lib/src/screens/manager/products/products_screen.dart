import 'package:flutter/material.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/models/company_product_model.dart';
import 'package:amaguexpress/src/models/store_company_model.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/src/screens/manager/hours/hours_screen.dart';
import 'package:amaguexpress/src/screens/manager/product/product_controller.dart';
import 'package:amaguexpress/src/screens/manager/product/product_screen.dart';
import 'package:amaguexpress/src/screens/manager/products/products_controller.dart';
import 'package:amaguexpress/src/screens/manager/products/widget/products_card.dart';
import 'package:amaguexpress/src/widgets/secondary_button.dart';
import 'package:provider/provider.dart';
import 'package:amaguexpress/constants/constants.dart';

class ProductsScreen extends StatelessWidget {
  ProductsScreen({super.key, required this.storeCompany});

  final StoreCompanyModel storeCompany;

  final pref = PreferencesProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor, // Usa tu color primario
        title: Text(storeCompany.name),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        HoursScreen(storeCompany: storeCompany),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month_outlined))
        ],
      ),
      body: ChangeNotifierProvider<ProductsController>.value(
        value: ProductsController(storeCompany),
        child: Consumer<ProductsController>(
          builder: (context, productsController, child) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Visibility(
                  visible: productsController.inAsyncCall,
                  child: const LinearProgressIndicator()),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                  kDefaultPadding,
                  kDefaultPadding,
                  kDefaultPadding,
                  0,
                ),
                padding: const EdgeInsets.all(kDefaultPadding),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        productsController.manualOffline
                            ? 'Estado: Cerrada temporalmente'
                            : 'Estado: Tienda operando',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: productsController.manualOffline
                            ? kPrimaryColor
                            : Colors.black87,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: productsController.inAsyncCall
                          ? null
                          : () async {
                              final ok = await productsController
                                  .toggleManualOffline();

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? productsController.manualOffline
                                            ? 'Tienda cerrada temporalmente'
                                            : 'Tienda reanudada'
                                        : 'No se pudo cambiar el estado. Verifica el horario de atención.',
                                  ),
                                ),
                              );
                            },
                      child: Text(
                        productsController.manualOffline
                            ? 'Reanudar'
                            : 'Pausar',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                  child: ListView.builder(
                itemCount: productsController.products.length,
                itemBuilder: (context, index) {
                  final product = productsController.products[index];

                  return Column(
                    children: [
                      ProductsCard(
                        productsController,
                        companyProduct: product,
                      ),
                    ],
                  );
                },
              )),
              SecondaryButton(
                color: Theme.of(context).colorScheme.secondary,
                text: S.of(context).bNewProduct,
                onPressed: () {
                  final productController =
                      Provider.of<ProductController>(context, listen: false);
                  productController.companyProduct = CompanyProductModel(id: 0);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductScreen(productsController),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
