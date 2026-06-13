import 'package:flutter/material.dart';
import 'package:amaguexpress/src/models/company_product_model.dart';
import 'package:amaguexpress/src/models/store_company_model.dart';
import 'package:amaguexpress/src/services/store_manager_service.dart';

class ProductsController extends ChangeNotifier {
  final StoreManagerService _storeManagerService = StoreManagerService();

  final StoreCompanyModel storeCompany;

  List<CompanyProductModel> _products = [];

  List<CompanyProductModel> get products => _products;

  ProductsController(this.storeCompany) {
    load();
  }

  bool _inAsyncCall = false;

  bool get inAsyncCall => _inAsyncCall;

  bool get manualOffline => storeCompany.manualOffline;

  set inAsyncCall(bool asyncCall) {
    _inAsyncCall = asyncCall;
    notifyListeners();
  }

  load() async {
    inAsyncCall = true;
    _products = await _storeManagerService.getProducts(storeCompany.company.id);
    inAsyncCall = false;
  }

  Future<bool> toggleManualOffline() async {
    inAsyncCall = true;

    final updatedStore = await _storeManagerService.updateManualOffline(
      storeCompany,
      !storeCompany.manualOffline,
    );

    inAsyncCall = false;

    if (updatedStore == null) {
      return false;
    }

    storeCompany.manualOffline = updatedStore.manualOffline;
    notifyListeners();
    return true;
  }

  setProducts(CompanyProductModel companyProduct) {
    final index = products.indexWhere((pr) => pr.id == companyProduct.id);
    if (index < 0) {
      products.insert(0, companyProduct);
    } else {
      products[index] = companyProduct;
    }
    notifyListeners();
  }
}
