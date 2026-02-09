import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/common/file_helper.dart';
import 'package:amaguexpress/src/screens/manager/product/product_controller.dart';
import 'package:amaguexpress/src/screens/manager/product/widget/description_input.dart';
import 'package:amaguexpress/src/screens/manager/product/widget/name_input.dart';
import 'package:amaguexpress/src/screens/manager/product/widget/price_input.dart';
import 'package:amaguexpress/src/screens/manager/product/widget/save_button.dart';
import 'package:amaguexpress/src/screens/manager/products/products_controller.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';
import 'package:amaguexpress/src/widgets/group_dropdown/group_dropdown.dart';
import 'package:amaguexpress/src/widgets/modal_progress_hud.dart';
import 'package:amaguexpress/src/widgets/upload_file/upload_file.dart';
import 'package:provider/provider.dart';

class ProductScreen extends StatelessWidget {
  ProductScreen(this.productsController, {super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProductsController productsController;

  @override
  Widget build(BuildContext context) {
    final productController = Provider.of<ProductController>(context);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: Text(productsController.storeCompany.name)),
      body: ModalProgressHUD(
        inAsyncCall: productController.inAsyncCall,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Visibility(
                  visible: productController.inAsyncCall,
                  child: const LinearProgressIndicator()),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(kDefaultPadding),
                    child: Column(
                      children: [
                        AvatarImage(
                            width: 200,
                            borderRadius: const BorderRadius.all(
                                Radius.circular(kDefaultPadding * 0.5)),
                            image: productController.companyProduct.image),
                        ElevatedButton(
                          onPressed: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => UploadFile((image) async {
                                productController.inAsyncCall = true;
                                String imageUpload = await uploadFile(
                                    image,
                                    'product/${productsController.storeCompany.company.id}',
                                    '${productsController.storeCompany.company.id}-${DateTime.now().toIso8601String()}',
                                    kTargetWidthProduct);
                                productController.companyProduct.image =
                                    imageUpload;
                                productController.inAsyncCall = false;
                              }),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_camera_outlined),
                              const SizedBox(width: kDefaultPadding * .5),
                              Text(S.of(context).bSelectPhoto),
                              const SizedBox(width: kDefaultPadding * .5),
                            ],
                          ),
                        ),
                        const SizedBox(height: kDefaultPadding),
                        GroupDropdown(productController),
                        const SizedBox(height: kDefaultPadding),
                        NameInput(productController: productController),
                        const SizedBox(height: kDefaultPadding),
                        DescriptionInput(productController: productController),
                        const SizedBox(height: kDefaultPadding),
                        PriceInput(productController: productController),
                        const SizedBox(height: kDefaultPadding * 6),
                      ],
                    ),
                  ),
                ),
              ),
              SaveButton(
                  formKey: _formKey,
                  productController: productController,
                  productsController: productsController)
            ],
          ),
        ),
      ),
    );
  }
}
