import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/src/models/address_model.dart';
import 'package:amaguexpress/src/models/cart_summary_model.dart';
import 'package:amaguexpress/src/models/category_model.dart';
import 'package:amaguexpress/src/models/company_model.dart';
import 'package:amaguexpress/src/models/fee_model.dart';
import 'package:amaguexpress/src/models/group_model.dart';
import 'package:amaguexpress/src/models/market_companies_response.dart';
import 'package:amaguexpress/src/models/market_products_response.dart';
import 'package:amaguexpress/src/models/order_model.dart';
import 'package:amaguexpress/src/models/product_model.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';

const _urlCompanies = 'client/market/companies';
const _urlCategories = 'client/market/categories';
const _urlProducts = 'client/market/products/company';
const _urlOrders = 'client/market/orders';
const _urlOrder = 'client/market/order/';
const _urlDeliveryCost = 'client/market/delivery-cost/companies';
const _urlBuy = 'client/market/buy';
const _urlQualify = 'client/market/qualify';

class MarketService {
  final prefs = PreferencesProvider();

  Future<List<OrderModel>> getOrders() async {
    List<OrderModel> orders = [];
    final client = http.Client();
    try {
      final resp = await client.get(
        Uri.parse('$kDomain$_urlOrders'),
        headers: {'Authorization': 'Bearer ${prefs.token}'},
      );

      if (resp.statusCode != 200) return orders;

      final dynamic decoded = json.decode(resp.body);
      if (decoded is! Map<String, dynamic>) return orders;

      final List<dynamic> list = (decoded['orders'] as List<dynamic>?) ?? [];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          orders.add(OrderModel.fromJson(item));
        } else if (item is String) {
          try {
            final dynamic parsed = json.decode(item);
            if (parsed is Map<String, dynamic>) {
              orders.add(OrderModel.fromJson(parsed));
            }
          } catch (_) {}
        }
      }
    } catch (err) {
      if (kDebugMode) {
        print('MarketService getOrders: $err');
      }
    } finally {
      client.close();
    }
    return orders;
  }

  Future<bool> markCancelledSeen(int orderId) async {
    final client = http.Client();
    try {
      final resp = await client.patch(
        Uri.parse('$kDomain$_urlOrder$orderId/cancel-seen'),
        headers: {'Authorization': 'Bearer ${prefs.token}'},
      );

      if (kDebugMode) {
        print('[MarketService] markCancelledSeen -> status=${resp.statusCode}');
        if (resp.statusCode != 200) {
          print('[MarketService] markCancelledSeen -> body=${resp.body}');
        }
      }

      return resp.statusCode == 200;
    } catch (err) {
      if (kDebugMode) {
        print('MarketService markCancelledSeen: $err');
      }
      return false;
    } finally {
      client.close();
    }
  }

  Future<OrderModel> getOrder(OrderModel order) async {
    final client = http.Client();
    try {
      final resp = await client.get(
        Uri.parse('$kDomain$_urlOrder${order.id}'),
        headers: {'Authorization': 'Bearer ${prefs.token}'},
      );
      if (resp.statusCode != 200) return order;

      final dynamic decoded = json.decode(resp.body);
      if (decoded is! Map<String, dynamic>) return order;

      final dynamic payload = decoded['order'];
      if (payload is Map<String, dynamic>) return OrderModel.fromJson(payload);

      if (payload is String) {
        try {
          final dynamic parsed = json.decode(payload);
          if (parsed is Map<String, dynamic>) {
            return OrderModel.fromJson(parsed);
          }
        } catch (_) {}
      }
      return order;
    } catch (err) {
      if (kDebugMode) {
        print('MarketService getOrder: $err');
      }
    } finally {
      client.close();
    }
    return order;
  }

  /// companyIds ejemplo: "1,2,3"
  Future<List<FeeModel>> deliveryCost(
    String companyIds,
    double lt,
    double lg, {
    bool isSumaryTaxi = false,
    double fromLtTaxi = 0,
    double fromLgTaxi = 0,
  }) async {
    List<FeeModel> fees = [];
    final client = http.Client();
    try {
      final url =
          '$kDomain$_urlDeliveryCost/$companyIds?longitude=$lg&latitude=$lt&fromlt=$fromLtTaxi&fromlg=$fromLgTaxi&isSumaryTaxi=${isSumaryTaxi.toString()}';

      final resp = await client.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${prefs.token}'},
      );

      if (kDebugMode) {
        print('[MarketService] deliveryCost -> url=$url');
        print('[MarketService] deliveryCost -> status=${resp.statusCode}');
        if (resp.statusCode != 200) {
          print('[MarketService] deliveryCost -> body=${resp.body}');
        }
      }

      if (resp.statusCode != 200) return fees;

      final dynamic decoded = json.decode(resp.body);
      if (decoded is! Map<String, dynamic>) return fees;

      final List<dynamic> feesJson = (decoded['fees'] as List<dynamic>?) ?? [];
      for (final item in feesJson) {
        if (item is Map<String, dynamic>) {
          fees.add(FeeModel.fromJson(item));
        } else if (item is String) {
          try {
            final dynamic parsed = json.decode(item);
            if (parsed is Map<String, dynamic>) {
              fees.add(FeeModel.fromJson(parsed));
            }
          } catch (_) {}
        }
      }

      if (kDebugMode) {
        print('[MarketService] deliveryCost -> feesCount=${fees.length}');
      }
    } catch (err) {
      if (kDebugMode) {
        print('MarketService deliveryCost: $err');
      }
    } finally {
      client.close();
    }
    return fees;
  }

  Future<MarketCompaniesResponse> getCompanies(
    CategoryModel selectedCategory,
    double lt,
    double lg, {
    String filter = '',
  }) async {
    List<ProductModel> products = [];
    List<CompanyModel> companies = [];

    final String param =
        selectedCategory.id > 0 ? '&categoryId=${selectedCategory.id}' : '';
    final client = http.Client();

    try {
      final resp = await client.get(
        Uri.parse(
          '$kDomain$_urlCompanies?longitude=$lg&latitude=$lt$param&name=${filter.toUpperCase()}',
        ),
      );

      if (resp.statusCode != 200) {
        return MarketCompaniesResponse(
            companies: companies, products: products);
      }

      final dynamic decoded = json.decode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        return MarketCompaniesResponse(
            companies: companies, products: products);
      }

      final List<dynamic> comps =
          (decoded['companies'] as List<dynamic>?) ?? [];
      for (final item in comps) {
        if (item is Map<String, dynamic>) {
          companies.add(CompanyModel.fromJson(item));
        } else if (item is String) {
          try {
            final dynamic parsed = json.decode(item);
            if (parsed is Map<String, dynamic>) {
              companies.add(CompanyModel.fromJson(parsed));
            }
          } catch (_) {}
        }
      }

      final List<dynamic> prods = (decoded['products'] as List<dynamic>?) ?? [];
      for (final item in prods) {
        if (item is Map<String, dynamic>) {
          products.add(ProductModel.fromJson(item));
        } else if (item is String) {
          try {
            final dynamic parsed = json.decode(item);
            if (parsed is Map<String, dynamic>) {
              products.add(ProductModel.fromJson(parsed));
            }
          } catch (_) {}
        }
      }

      return MarketCompaniesResponse(companies: companies, products: products);
    } catch (err) {
      if (kDebugMode) {
        print('MarketService getCompanies: $err');
      }
    } finally {
      client.close();
    }

    return MarketCompaniesResponse(companies: companies, products: products);
  }

  Future<List<CategoryModel>> getCategories(double lt, double lg) async {
    List<CategoryModel> categories = [];
    final client = http.Client();

    try {
      final resp = await client.get(
        Uri.parse('$kDomain$_urlCategories?longitude=$lg&latitude=$lt'),
      );
      if (resp.statusCode != 200) return categories;

      final dynamic decoded = json.decode(resp.body);
      if (decoded is! Map<String, dynamic>) return categories;

      final List<dynamic> cats =
          (decoded['categories'] as List<dynamic>?) ?? [];
      for (final item in cats) {
        if (item is Map<String, dynamic>) {
          categories.add(CategoryModel.fromJson(item));
        } else if (item is String) {
          try {
            final dynamic parsed = json.decode(item);
            if (parsed is Map<String, dynamic>) {
              categories.add(CategoryModel.fromJson(parsed));
            }
          } catch (_) {}
        }
      }
    } catch (err) {
      if (kDebugMode) {
        print('MarketService getCategories: $err');
      }
    } finally {
      client.close();
    }
    return categories;
  }

  Future<MarketProductsResponse> getProducts(int companyId, int groupId) async {
    List<ProductModel> products = [];
    List<GroupModel> groups = [];

    final client = http.Client();
    try {
      final resp = await client.get(
        Uri.parse('$kDomain$_urlProducts/$companyId?groupId=$groupId'),
      );

      if (resp.statusCode != 200) {
        return MarketProductsResponse(groups: groups, products: products);
      }

      final dynamic decoded = json.decode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        return MarketProductsResponse(groups: groups, products: products);
      }

      final List<dynamic> prods = (decoded['products'] as List<dynamic>?) ?? [];
      for (final item in prods) {
        if (item is Map<String, dynamic>) {
          products.add(ProductModel.fromJson(item));
        } else if (item is String) {
          try {
            final dynamic parsed = json.decode(item);
            if (parsed is Map<String, dynamic>) {
              products.add(ProductModel.fromJson(parsed));
            }
          } catch (_) {}
        }
      }

      final List<dynamic> grps = (decoded['groups'] as List<dynamic>?) ?? [];
      for (final item in grps) {
        if (item is Map<String, dynamic>) {
          groups.add(GroupModel.fromJson(item));
        } else if (item is String) {
          try {
            final dynamic parsed = json.decode(item);
            if (parsed is Map<String, dynamic>) {
              groups.add(GroupModel.fromJson(parsed));
            }
          } catch (_) {}
        }
      }
    } catch (err) {
      if (kDebugMode) {
        print('MarketService getProducts: $err');
      }
    } finally {
      client.close();
    }

    return MarketProductsResponse(groups: groups, products: products);
  }

  // ============================================================
  // BUY (fix definitivo)
  // ============================================================

  dynamic _tryDecodeJsonString(dynamic v) {
    if (v is String) {
      final s = v.trim();
      if ((s.startsWith('{') && s.endsWith('}')) ||
          (s.startsWith('[') && s.endsWith(']'))) {
        try {
          return json.decode(s);
        } catch (_) {
          return v;
        }
      }
    }
    return v;
  }

  int? _extractOrderId(dynamic decoded) {
    try {
      if (decoded is Map<String, dynamic>) {
        final dynamic maybeOrder = decoded['order'] ?? decoded;
        if (maybeOrder is Map<String, dynamic>) {
          final id = maybeOrder['id'];
          if (id is int) return id;
          if (id is String) return int.tryParse(id);
        }
        final id2 = decoded['id'];
        if (id2 is int) return id2;
        if (id2 is String) return int.tryParse(id2);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<OrderModel?> _fetchOrderById(int orderId) async {
    final client = http.Client();
    try {
      final resp = await client.get(
        Uri.parse('$kDomain$_urlOrder$orderId'),
        headers: {'Authorization': 'Bearer ${prefs.token}'},
      );

      if (resp.statusCode != 200) {
        if (kDebugMode) {
          print('[MarketService] _fetchOrderById -> status=${resp.statusCode}');
          print('[MarketService] _fetchOrderById -> body=${resp.body}');
        }
        return null;
      }

      dynamic decoded = json.decode(resp.body);
      decoded = _tryDecodeJsonString(decoded);

      if (decoded is! Map<String, dynamic>) return null;

      dynamic payload = decoded['order'] ?? decoded;
      payload = _tryDecodeJsonString(payload);

      if (payload is! Map<String, dynamic>) return null;

      return OrderModel.fromJson(payload);
    } catch (e) {
      if (kDebugMode) {
        print('[MarketService] _fetchOrderById error: $e');
      }
      return null;
    } finally {
      client.close();
    }
  }

  /// IMPORTANTE:
  /// - Para NAT, el backend responde 201 con un objeto incompleto (store:{id} y productos mínimos)
  /// - OrderModel.fromJson() explota porque espera objetos anidados completos.
  /// Solución: POST /buy -> extraer id -> GET /order/:id -> parse del objeto completo.
  Future<OrderModel?> buy(
    CartSummaryModel cartSummary,
    AddressModel address,
    int payment,
  ) async {
    final client = http.Client();
    try {
      final url = '$kDomain$_urlBuy';

      final resp = await client.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${prefs.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: cartSummary.toHttpBodyBuy(address, payment),
      );

      if (kDebugMode) {
        print('[MarketService] buy -> url=$url');
        print('[MarketService] buy -> status=${resp.statusCode}');
        print('[MarketService] buy -> body=${resp.body}');
      }

      if (resp.statusCode != 200 && resp.statusCode != 201) return null;

      // 1) decode response
      dynamic decoded = json.decode(resp.body);
      decoded = _tryDecodeJsonString(decoded);

      // 2) extrae id lo más rápido posible
      final int? orderId = _extractOrderId(decoded);

      // 3) intenta traer el objeto completo por /order/:id
      if (orderId != null && orderId > 0) {
        final fetched = await _fetchOrderById(orderId);
        if (fetched != null) return fetched;
      }

      // 4) fallback: si por alguna razón no se pudo hacer GET, intenta parsear lo que vino
      // (ojo: para NAT puede seguir fallando, pero ya intentamos la vía correcta primero)
      if (decoded is Map<String, dynamic>) {
        final dynamic payload =
            _tryDecodeJsonString(decoded['order'] ?? decoded);
        if (payload is Map<String, dynamic>) {
          try {
            return OrderModel.fromJson(payload);
          } catch (e) {
            if (kDebugMode) {
              print(
                  '[MarketService] buy -> fallback OrderModel.fromJson failed: $e');
            }
            return null;
          }
        }
      }

      return null;
    } catch (err) {
      if (kDebugMode) {
        print('MarketService buy: $err');
      }
      return null;
    } finally {
      client.close();
    }
  }

  Future<bool> qualify(OrderModel order) async {
    final client = http.Client();
    try {
      final resp = await client.patch(
        Uri.parse('$kDomain$_urlQualify/${order.id}'),
        headers: {
          'Authorization': 'Bearer ${prefs.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({"scoreClient": order.scoreClient}),
      );
      if (resp.statusCode == 200) return true;
    } catch (err) {
      if (kDebugMode) {
        print('MarketService qualify: $err');
      }
    } finally {
      client.close();
    }
    return false;
  }
}
