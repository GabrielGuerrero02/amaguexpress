import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/src/models/company_product_model.dart';
import 'package:amaguexpress/src/screens/manager/product/product_controller.dart';
import 'package:amaguexpress/src/screens/manager/product/product_screen.dart';
import 'package:amaguexpress/src/screens/manager/products/products_controller.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';
import 'package:provider/provider.dart';

class ProductsCard extends StatelessWidget {
  const ProductsCard(
    this.productsController, {
    required this.companyProduct,
    super.key,
  });

  final ProductsController productsController;
  final CompanyProductModel companyProduct;

  @override
  Widget build(BuildContext context) {
    final isVisible = companyProduct.isVisible;

    return Opacity(
      opacity: isVisible ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          children: [
            ListTile(
              onTap: () {
                final productController =
                    Provider.of<ProductController>(context, listen: false);
                productController.companyProduct = companyProduct;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductScreen(productsController),
                  ),
                );
              },
              leading: AvatarImage(
                image: companyProduct.image,
                width: 56,
                height: 56,
              ),
              title: Text(
                companyProduct.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                companyProduct.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: isVisible ? 'Ocultar producto' : 'Mostrar producto',
                icon: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isVisible ? kPrimaryColor : Colors.blueGrey,
                ),
                onPressed: () async {
                  final ok = await productsController
                      .toggleProductVisibility(companyProduct);

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        ok
                            ? (isVisible
                                ? 'Producto ocultado'
                                : 'Producto visible')
                            : 'No se pudo actualizar el producto',
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: kPrimaryColor, thickness: 1)
          ],
        ),
      ),
    );
  }
}
