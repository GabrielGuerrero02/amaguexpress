import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/src/models/company_product_model.dart';
import 'package:amaguexpress/src/models/hour_model.dart';
import 'package:amaguexpress/src/models/store_company_model.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';

const _urlGetStoresCompanies = 'manager/store/companies';
const _urlGetProducts = 'manager/store/products';
const _urlCreateProduct = 'manager/store/product';
const _urlUpdateProduct = 'manager/store/product';
const _urlUpdateProductVisibility = 'manager/store/product';
const _urlGetHours = 'manager/store/hours';
const _urlUpdateHour = 'manager/store/hours';
const _urlManualOffline = 'manager/store';

class StoreManagerService {
  final prefs = PreferencesProvider();

  String? lastErrorMessage;

  String? _extractErrorMessage(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final message = decoded['message'];
      if (message is String) return message;
      if (message is List) return message.join('\n');

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<HourModel> updateHour(HourModel hour) async {
    var client = http.Client();
    try {
      final resp =
          await client.patch(Uri.parse('$kDomain$_urlUpdateHour/${hour.id}'),
              headers: {
                'Authorization': 'Bearer ${prefs.token}',
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: hour.toHttpBodyUpdate());

      if (resp.statusCode != 200) return hour;
      Map<String, dynamic> decodedResp = json.decode(resp.body);
      return HourModel.fromJson(decodedResp['hour']);
    } catch (err) {
      if (kDebugMode) {
        print('StoreManagerService updateHour: $err');
      }
    } finally {
      client.close();
    }
    return hour;
  }

  Future<List<HourModel>> getHours(int storeId) async {
    List<HourModel> hours = [];
    var client = http.Client();
    try {
      final resp = await client.get(
        Uri.parse('$kDomain$_urlGetHours/$storeId'),
        headers: {'Authorization': 'Bearer ${prefs.token}'},
      );
      if (resp.statusCode != 200) return hours;
      Map<String, dynamic> decodedResp = json.decode(resp.body);
      for (var item in decodedResp['hours']) {
        hours.add(HourModel.fromJson(item));
      }
    } catch (err) {
      if (kDebugMode) {
        print('StoreManagerService getHours: $err');
      }
    } finally {
      client.close();
    }
    return hours;
  }

  Future<List<StoreCompanyModel>> getCompanies() async {
    List<StoreCompanyModel> companies = [];
    var client = http.Client();
    try {
      final resp = await client.get(
        Uri.parse('$kDomain$_urlGetStoresCompanies'),
        headers: {'Authorization': 'Bearer ${prefs.token}'},
      );
      if (resp.statusCode != 200) return companies;
      Map<String, dynamic> decodedResp = json.decode(resp.body);
      for (var item in decodedResp['stores']) {
        companies.add(StoreCompanyModel.fromJson(item));
      }
    } catch (err) {
      if (kDebugMode) {
        print('StoreManagerService getCompanies: $err');
      }
    } finally {
      client.close();
    }
    return companies;
  }

  Future<List<CompanyProductModel>> getProducts(int companyId) async {
    List<CompanyProductModel> products = [];
    var client = http.Client();
    try {
      final resp = await client.get(
        Uri.parse('$kDomain$_urlGetProducts/$companyId'),
        headers: {'Authorization': 'Bearer ${prefs.token}'},
      );
      if (resp.statusCode != 200) return products;
      Map<String, dynamic> decodedResp = json.decode(resp.body);
      for (var item in decodedResp['products']) {
        products.add(CompanyProductModel.fromJson(item));
      }
    } catch (err) {
      if (kDebugMode) {
        print('StoreManagerService getProducts: $err');
      }
    } finally {
      client.close();
    }
    return products;
  }

  Future<CompanyProductModel?> createProduct(
      CompanyProductModel companyProduct, int companyId) async {
    lastErrorMessage = null;
    var client = http.Client();
    try {
      final resp = await client.post(Uri.parse('$kDomain$_urlCreateProduct'),
          headers: {
            'Authorization': 'Bearer ${prefs.token}',
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: companyProduct.toHttpBodyCreate(companyId));
      if (resp.statusCode != 201) {
        lastErrorMessage =
            _extractErrorMessage(resp.body) ?? 'No se pudo crear el producto';

        if (kDebugMode) {
          print(
              '[StoreManagerService] createProduct -> status=${resp.statusCode}');
          print('[StoreManagerService] createProduct -> body=${resp.body}');
          print(
              '[StoreManagerService] createProduct -> message=$lastErrorMessage');
        }
        return null;
      }
      Map<String, dynamic> decodedResp = json.decode(resp.body);
      return CompanyProductModel.fromJson(decodedResp['product']);
    } catch (err) {
      if (kDebugMode) {
        print('StoreManagerService createProduct: $err');
      }
    } finally {
      client.close();
    }
    return null;
  }

  Future<CompanyProductModel?> updateProduct(
      CompanyProductModel companyProduct) async {
    lastErrorMessage = null;
    var client = http.Client();
    try {
      final resp = await client.patch(
          Uri.parse('$kDomain$_urlUpdateProduct/${companyProduct.id}'),
          headers: {
            'Authorization': 'Bearer ${prefs.token}',
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: companyProduct.toHttpBodyUpdate());
      if (resp.statusCode != 200) {
        lastErrorMessage = _extractErrorMessage(resp.body) ??
            'No se pudo actualizar el producto';

        if (kDebugMode) {
          print(
              '[StoreManagerService] updateProduct -> status=${resp.statusCode}');
          print('[StoreManagerService] updateProduct -> body=${resp.body}');
        }
        return null;
      }
      Map<String, dynamic> decodedResp = json.decode(resp.body);
      return CompanyProductModel.fromJson(decodedResp['product']);
    } catch (err) {
      if (kDebugMode) {
        print('StoreManagerService updateProduct: $err');
      }
    } finally {
      client.close();
    }
    return null;
  }

  Future<CompanyProductModel?> updateProductVisibility(
      CompanyProductModel companyProduct, bool isVisible) async {
    var client = http.Client();
    try {
      final resp = await client.patch(
        Uri.parse(
            '$kDomain$_urlUpdateProductVisibility/${companyProduct.id}/visibility'),
        headers: {
          'Authorization': 'Bearer ${prefs.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'isVisible': isVisible}),
      );

      final decodedResp = json.decode(resp.body);

      if (resp.statusCode != 200) {
        if (kDebugMode) {
          print(
              'StoreManagerService updateProductVisibility: ${decodedResp['message']}');
        }
        return null;
      }

      return CompanyProductModel.fromJson(decodedResp['product']);
    } catch (err) {
      if (kDebugMode) {
        print('StoreManagerService updateProductVisibility: $err');
      }
    } finally {
      client.close();
    }
    return null;
  }

  Future<StoreCompanyModel?> updateManualOffline(
      StoreCompanyModel storeCompany, bool manualOffline) async {
    var client = http.Client();
    try {
      final resp = await client.patch(
        Uri.parse(
            '$kDomain$_urlManualOffline/${storeCompany.id}/manual-offline'),
        headers: {
          'Authorization': 'Bearer ${prefs.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'manualOffline': manualOffline}),
      );

      final decodedResp = json.decode(resp.body);

      if (resp.statusCode != 200) {
        if (kDebugMode) {
          print(
              'StoreManagerService updateManualOffline: ${decodedResp['message']}');
        }
        return null;
      }

      storeCompany.manualOffline =
          decodedResp['store']['manualOffline'] ?? manualOffline;

      return storeCompany;
    } catch (err) {
      if (kDebugMode) {
        print('StoreManagerService updateManualOffline: $err');
      }
    } finally {
      client.close();
    }
    return null;
  }
}
