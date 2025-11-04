import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/src/models/store_company_model.dart';
import 'package:amaguexpress/src/screens/manager/company/company_controller.dart';
import 'package:amaguexpress/src/screens/manager/products/products_screen.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';

class CompanyCard extends StatelessWidget {
  const CompanyCard(
    this.companyController, {
    required this.storeCompany,
    super.key,
  });

  final CompanyController companyController;
  final StoreCompanyModel storeCompany;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ProductsScreen(storeCompany: storeCompany),
                ),
              );
            },
            trailing:
                AvatarImage(image: storeCompany.company.marker, width: 35),
            leading: AvatarImage(image: storeCompany.company.image),
            title: Text(storeCompany.name),
            subtitle: Text(storeCompany.address),
          ),
          const Divider(color: kPrimaryColor, thickness: 1)
        ],
      ),
    );
  }
}
