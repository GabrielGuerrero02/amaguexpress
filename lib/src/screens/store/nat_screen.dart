import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/src/models/address_model.dart';
import 'package:amaguexpress/src/models/product_model.dart';
import 'package:amaguexpress/src/models/store_company_model.dart' as scm;
import 'package:amaguexpress/src/provider/db_provider.dart';
import 'package:amaguexpress/src/screens/address/address_screen.dart';
import 'package:amaguexpress/src/screens/addresses/addresses_controller.dart';
import 'package:amaguexpress/src/screens/cart_summary/cart_summary_screen.dart';
import 'package:amaguexpress/src/services/store_manager_service.dart';

/// NAT&: solicitud de motorizado SOLO ENVÍO (sin valor de productos).
///
/// Reglas:
/// - TIENDA: se selecciona desde StoreManagerService.getCompanies().
/// - ORIGEN: se fija automáticamente con la ubicación de la tienda seleccionada (no editable).
/// - DESTINO: se selecciona desde direcciones (combo) y puede agregarse nueva ubicación.
/// - Con TIENDA + DESTINO seleccionados, se habilita el botón "Ver precio y pagar" (flujo normal).
class NatScreen extends StatefulWidget {
  const NatScreen({super.key});

  @override
  State<NatScreen> createState() => _NatScreenState();
}

class _NatScreenState extends State<NatScreen> {
  late final AddressesController _addressesController;

  // TIENDA
  final StoreManagerService _storeService = StoreManagerService();
  bool _storesLoading = false;
  String? _storesError;
  List<scm.StoreCompanyModel> _stores = [];
  scm.StoreCompanyModel? _selectedStore;

  // DESTINO
  int? _destinationIndex;
  AddressModel? _destinationAddress;

  @override
  void initState() {
    super.initState();
    _addressesController = AddressesController();
    _addressesController.load();
    _loadStores();
  }

  String _sqlSafe(String value) => value.replaceAll("'", ' ');

  Future<void> _loadStores() async {
    if (_storesLoading) return;

    setState(() {
      _storesLoading = true;
      _storesError = null;
    });

    try {
      final list = await _storeService.getCompanies(); // <-- método real
      _stores = list;

      if (_stores.isEmpty) {
        _selectedStore = null;
        _storesError =
            'No se encontraron tiendas disponibles para este usuario.';
      } else {
        // Mantener selección si existe; caso contrario usar la primera
        final currentId = _selectedStore?.id;
        final exists =
            currentId != null && _stores.any((s) => s.id == currentId);
        _selectedStore = exists
            ? _stores.firstWhere((s) => s.id == currentId)
            : _stores.first;
      }
    } catch (e) {
      _stores = [];
      _selectedStore = null;
      _storesError = 'No se pudieron cargar tus tiendas. Detalle: $e';
    } finally {
      if (!mounted) return;
      setState(() => _storesLoading = false);
    }
  }

  // Convertimos la ubicación del modelo de tienda (scm.Location) al Location del address_model.dart
  // Preferimos `store.location` y, si viene en 0/0, usamos `store.company.location` como fallback.
  Location? _storeToAddressLocation(scm.StoreCompanyModel? store) {
    if (store == null) return null;

    double x = store.location.x;
    double y = store.location.y;

    // Fallback: algunas respuestas traen location en 0/0 a nivel store, pero sí viene en company
    if (x == 0 && y == 0) {
      x = store.company.location.x;
      y = store.company.location.y;
    }

    if (x == 0 && y == 0) return null;
    return Location(x: x, y: y);
  }

  String _storeTitle(scm.StoreCompanyModel c) {
    final name = (c.name).trim();
    return name.isEmpty ? 'Tienda #${c.id}' : name;
  }

  // -------- UI styles --------
  OutlineInputBorder _roundedBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1),
    );
  }

  InputDecoration _fieldDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: _roundedBorder(Colors.black12),
      border: _roundedBorder(Colors.black12),
      focusedBorder: _roundedBorder(kPrimaryColor),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black12),
      borderRadius: BorderRadius.circular(12),
    );
  }

  // -------- Flow rules --------
  bool get _canContinue {
    final hasStore = _selectedStore != null &&
        _storeToAddressLocation(_selectedStore) != null;
    final hasDestination = _destinationAddress?.location != null;
    return hasStore && hasDestination;
  }

  Location? _baseLocationForAddressCreate() {
    // Para abrir el mapa al crear dirección, usamos una base (tienda seleccionada o cualquier dirección existente).
    final storeLoc = _storeToAddressLocation(_selectedStore);
    if (storeLoc != null) return storeLoc;

    if (_destinationAddress?.location != null)
      return _destinationAddress!.location;

    if (_addressesController.addresses.isNotEmpty) {
      return _addressesController.addresses.first.location;
    }
    return null;
  }

  Future<void> _addNewDestinationAddress() async {
    final baseLocation = _baseLocationForAddressCreate();
    if (baseLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Primero registra una dirección en el módulo Direcciones.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AddressScreen(address: AddressModel(location: baseLocation)),
      ),
    );

    await _addressesController.load();
    if (!mounted) return;

    // Si ya hay direcciones, seleccionar la primera (o mantiene la actual si quieres, pero para pruebas así basta)
    if (_addressesController.addresses.isNotEmpty) {
      setState(() {
        _destinationIndex = 0;
        _destinationAddress = _addressesController.addresses[0];
      });
    }
  }

  Future<void> _goToCheckoutNat() async {
    if (!_canContinue) return;

    final store = _selectedStore;
    final destinationSelected = _destinationAddress;

    if (store == null || destinationSelected == null) return;

    final originLocation = _storeToAddressLocation(store);
    final destinationLocation = destinationSelected.location;

    if (originLocation == null || destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Origen y destino deben tener ubicación válida.')),
      );
      return;
    }

    // Guardamos destino (Address) para que CartSummary use el mismo patrón existente.
    final destination = AddressModel(
      location: destinationLocation,
      address: _sqlSafe((destinationSelected.address).trim()),
      alias: _sqlSafe((destinationSelected.alias).trim().isEmpty
          ? 'Destino'
          : destinationSelected.alias.trim()),
    );

    // Seed local DB: un address + un producto dummy
    await DBProvider.db.deleteAddress();
    await DBProvider.db.deleteAllProduct(TypesCompany.store);

    await DBProvider.db.createAddress(destination);

    // Producto dummy (precio 0). Para el cálculo de envío, el flujo normal usa `companyId`.
    // En StoreManager vienen dos IDs: `store.id` y `store.company.id`. El flujo de Market/CartSummary
    // trabaja con IDs de Company, por eso usamos `store.company.id`.
    final storeName = (store.company.name).trim().isEmpty
        ? _storeTitle(store)
        : store.company.name;

    final dummy = ProductModel(
      id: 1,
      companyId: store.company.id,
      companyName: storeName,
      name: 'Nodo Automàtico de Transporte(NAT&) - $storeName',
      description: 'Servicio de entrega',
      type: TypesCompany.store,
      price: 0,
      image: '',
      number: 1,

      // IMPORTANTE: aquí se queda el flag técnico, pero NO debe mostrarse en UI
      note: 'NAT_DELIVERY_ONLY|storeId=${store.id}',

      lt: originLocation.x,
      lg: originLocation.y,
    );

    await DBProvider.db.createProduct(
      dummy,
      TypesCompany.store,
      lt: originLocation.x,
      lg: originLocation.y,
    );

    if (!mounted) return;

    // Abre el flujo normal de resumen / precio / pago.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartSummaryScreen(
          isSummaryNat: true,
          fromLtNat: originLocation.x,
          fromLgNat: originLocation.y,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _addressesController,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text('Solicitar motorizado'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------------- TIENDA ----------------
                      const Text(
                        'Tienda',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_storesLoading) const LinearProgressIndicator(),
                            if (_storesError != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  _storesError!,
                                  style: TextStyle(
                                      color: Colors.black.withOpacity(0.65)),
                                ),
                              ),
                            DropdownButtonFormField<int>(
                              value: () {
                                if (_selectedStore == null) return null;
                                final idx = _stores.indexWhere(
                                    (s) => s.id == _selectedStore!.id);
                                return idx >= 0 ? idx : null;
                              }(),
                              isExpanded: true,
                              items: _stores.isEmpty
                                  ? const []
                                  : List.generate(_stores.length, (i) {
                                      final s = _stores[i];
                                      return DropdownMenuItem(
                                        value: i,
                                        child: Text(
                                          _storeTitle(s),
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }),
                              onChanged: _stores.isEmpty
                                  ? null
                                  : (v) {
                                      if (v == null) return;
                                      setState(
                                          () => _selectedStore = _stores[v]);
                                    },
                              decoration:
                                  _fieldDecoration(label: 'Selecciona tienda'),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _loadStores,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kPrimaryColor,
                                  side: const BorderSide(
                                      color: kPrimaryColor, width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text(
                                  'Actualizar lista de tiendas',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ---------------- ORIGEN (de tienda) ----------------
                      const Text(
                        'Origen',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: _cardDecoration(),
                        child: Builder(
                          builder: (_) {
                            if (_selectedStore == null) {
                              return Text(
                                'Selecciona una tienda para fijar el origen.',
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.65)),
                              );
                            }

                            final originLoc =
                                _storeToAddressLocation(_selectedStore);
                            if (originLoc == null) {
                              return Text(
                                'La tienda seleccionada no tiene ubicación configurada.',
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.65)),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _storeTitle(_selectedStore!),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ubicación de origen (no editable)',
                                  style: TextStyle(
                                      color: Colors.black.withOpacity(0.6)),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F6F6),
                                    border: Border.all(color: Colors.black12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (_selectedStore!.address).trim().isEmpty
                                        ? _storeTitle(_selectedStore!)
                                        : _selectedStore!.address,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ---------------- DESTINO ----------------
                      const Text(
                        'Destino',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: _cardDecoration(),
                        child: Consumer<AddressesController>(
                          builder: (context, c, _) {
                            if (c.inAsyncCall)
                              return const LinearProgressIndicator();

                            final list = c.addresses;

                            if (_destinationIndex == null && list.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                setState(() {
                                  _destinationIndex = 0;
                                  _destinationAddress = list[0];
                                });
                              });
                            }

                            if (list.isEmpty) {
                              return Text(
                                'No hay direcciones registradas. Crea una nueva para seleccionar el destino.',
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.65)),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<int>(
                                  value: _destinationIndex,
                                  isExpanded: true,
                                  items: List.generate(list.length, (i) {
                                    final a = list[i];
                                    final alias = (a.alias).trim();
                                    final title =
                                        alias.isEmpty ? 'Dirección' : alias;
                                    final subtitle = (a.address).trim();
                                    return DropdownMenuItem(
                                      value: i,
                                      child: Text(
                                        subtitle.isEmpty
                                            ? title
                                            : '$title - $subtitle',
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                  selectedItemBuilder: (context) {
                                    return List.generate(list.length, (i) {
                                      final a = list[i];
                                      final alias = (a.alias).trim();
                                      final title =
                                          alias.isEmpty ? 'Dirección' : alias;
                                      final subtitle = (a.address).trim();
                                      final text = subtitle.isEmpty
                                          ? title
                                          : '$title - $subtitle';
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          text,
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    });
                                  },
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() {
                                      _destinationIndex = v;
                                      _destinationAddress = list[v];
                                    });
                                  },
                                  decoration: _fieldDecoration(
                                      label: 'Ubicación de destino'),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _addNewDestinationAddress,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: kPrimaryColor,
                                      side: const BorderSide(
                                          color: kPrimaryColor, width: 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    child: const Text(
                                      'Agregar nueva ubicación de destino',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ---------------- CTA ----------------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canContinue ? _goToCheckoutNat : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: kPrimaryColor.withOpacity(0.35),
                    disabledForegroundColor: Colors.white.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Ver precio y pagar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
