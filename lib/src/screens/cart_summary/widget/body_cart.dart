import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/models/address_model.dart';
import 'package:amaguexpress/src/provider/db_provider.dart';
import 'package:amaguexpress/src/screens/cart_summary/cart_summary_controller.dart';
import 'package:amaguexpress/src/screens/cart_summary/widget/company_products.dart';
import 'package:amaguexpress/src/screens/main/tab1_controller.dart';
import 'package:amaguexpress/src/screens/main/tab2_controller.dart';
import 'package:amaguexpress/src/screens/main/tab_main_controller.dart';
import 'package:amaguexpress/src/widgets/address_dropdown/address_dropdown.dart';
import 'package:amaguexpress/src/widgets/address_dropdown/address_dropdown_controller.dart';
import 'package:amaguexpress/src/widgets/icon_cart/icon_cart_controller.dart';
import 'package:amaguexpress/src/widgets/money_input.dart';
import 'package:amaguexpress/src/widgets/payment_dropdown/payment_dropdown.dart';
import 'package:amaguexpress/src/widgets/payment_dropdown/payment_dropdown_controller.dart';
import 'package:amaguexpress/src/widgets/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:amaguexpress/src/screens/cart_summary/payphone_webview.dart';

class BodyCart extends StatefulWidget {
  const BodyCart({
    super.key,
  });

  @override
  State<BodyCart> createState() => _BodyCartState();
}

class _BodyCartState extends State<BodyCart> {
  int? _lastPaymentType;

  @override
  Widget build(BuildContext context) {
    final paymentController = Provider.of<PaymentDropdownController>(context);
    final cartSummaryController = Provider.of<CartSummaryController>(context);
    final double width = MediaQuery.of(context).size.width;

    // ✅ Muestra un popup informativo SOLO cuando el usuario selecciona EFECTIVO
    _maybeShowCashInfo(paymentController.payment.type);

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: AddressDropdown(isScreenMain: false)),
        const SliverToBoxAdapter(child: PaymentDropdown()),
        if (cartSummaryController.money > 0)
          SliverToBoxAdapter(child: MoneyInput(cartSummaryController.money)),
        SliverToBoxAdapter(
          child: CompanyProducts(
            cartSummaryController: cartSummaryController,
            width: width,
          ),
        ),
        SliverToBoxAdapter(
          child: _paymentMethodButton(
            context,
            paymentController,
            cartSummaryController,
          ),
        ),
      ],
    );
  }

  void _maybeShowCashInfo(int currentType) {
    final wasCash = _lastPaymentType == TypesPayment.cash;
    final isCash = currentType == TypesPayment.cash;
    final wasCard = _lastPaymentType == TypesPayment.money;
    final isCard = currentType == TypesPayment.money;

    // Solo disparar cuando cambia a efectivo o a tarjeta
    if ((isCash && !wasCash) || (isCard && !wasCard)) {
      // Actualizamos inmediatamente para evitar múltiples disparos por rebuild
      _lastPaymentType = currentType;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Configuración del popup según el método seleccionado
        final String titleText =
            isCash ? 'Pago en efectivo' : 'Pago con tarjeta';
        final IconData titleIcon =
            isCash ? Icons.payments_outlined : Icons.credit_card;
        final String contentText = isCash
            ? 'Aceptamos billetes de hasta \$20. Si es posible, paga con el valor exacto.\n\n'
                'Recuerda cancelar al motorizado el total del pedido, incluido el servicio de entrega.'
            : 'Para pagar con tarjeta necesitas la app PayPhone.\n\n'
                '1) Descárgala desde App Store o Google Play.\n'
                '2) Registra tu tarjeta de crédito o débito (Visa, Mastercard o Diners).\n'
                '3) Vuelve a AmaguExpress y presiona “Pagar” para generar el cobro en PayPhone.';

        showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            titlePadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Icon(titleIcon, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titleText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            content: Text(
              contentText,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        );
      });

      return;
    }

    // Mantener último estado
    _lastPaymentType = currentType;
  }

  Widget _paymentMethodButton(
    BuildContext context,
    PaymentDropdownController paymentController,
    CartSummaryController cartSummaryController,
  ) {
    double total = double.parse(
        cartSummaryController.total.toStringAsFixed(kCoinDecimals));

    switch (paymentController.payment.type) {
      case TypesPayment.money:
        total = total - cartSummaryController.money;
        if (total < 0) total = 0;
        total = double.parse(total.toStringAsFixed(kCoinDecimals));

        return PrimaryButton(
          color: Theme.of(context).colorScheme.primary,
          text: "${S.of(context).bPay} $total $kCoin",
          icon: Icons.credit_score_outlined,
          onPressed: () {
            _onPressedBuy(
              context,
              paymentController,
              cartSummaryController,
              total,
            );
          },
        );

      case TypesPayment.cash:
        return PrimaryButton(
          color: Theme.of(context).colorScheme.primary,
          text:
              "${S.of(context).bPay} ${total.toStringAsFixed(kCoinDecimals)} $kCoin",
          icon: Icons.payments_outlined,
          onPressed: () {
            // ✅ Flujo intacto (no se altera el pagar)
            _onPressedBuy(
              context,
              paymentController,
              cartSummaryController,
              total,
            );
          },
        );

      default:
        return PrimaryButton(
          color: Theme.of(context).colorScheme.primary,
          text:
              "${S.of(context).bPay} ${total.toStringAsFixed(kCoinDecimals)} $kCoin",
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: kErrorColor,
                content: Text(S.of(context).lselectPayment),
              ),
            );
          },
        );
    }
  }

  _onPressedBuy(
    BuildContext context,
    PaymentDropdownController paymentController,
    CartSummaryController cartSummaryController,
    double total,
  ) async {
    if (cartSummaryController.products.isEmpty) return;

    if (paymentController.payment.type == TypesPayment.cash && total <= 0) {
      return;
    }

    if (paymentController.payment.type == TypesPayment.money) {
      if (cartSummaryController.money <= 0 && total <= 0) {
        return;
      }

      if (total > 0 && total < kMinPurchaseAmountCard) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: kErrorColor,
          duration: const Duration(seconds: 12),
          content: Text(S
              .of(context)
              .errMinPurchaseAmountCard(kMinPurchaseAmountCard, kCoin)),
        ));
        return;
      }
    }

    paymentController.isPaymentSelected = false;

    final iconCartController =
        Provider.of<IconCartController>(context, listen: false);
    final tabManController =
        Provider.of<TabManController>(context, listen: false);
    final tab1Controller = Provider.of<Tab1Controller>(context, listen: false);
    final tab2Controller = Provider.of<Tab2Controller>(context, listen: false);
    final addressDropdownController =
        Provider.of<AddressDropdownController>(context, listen: false);

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final s = S.of(context);

    AddressModel? address = await DBProvider.db.loadAddress();

    if (address == null || address.id <= 0) {
      scaffoldMessenger.showSnackBar(
        SnackBar(backgroundColor: kErrorColor, content: Text(s.bSelectAddress)),
      );
      return;
    }

    // ✅ Evita el falso mensaje de “Seleccione una dirección”:
    // En algunos flujos (ej. NAT) el dropdown puede quedar en 0 o desincronizado
    // aunque ya exista una dirección válida guardada en DB.
    final currentDropdownId =
        int.tryParse(addressDropdownController.dropdown.value.toString()) ?? 0;

    if (currentDropdownId == 0 || currentDropdownId != address.id) {
      addressDropdownController.dropdown.value = address.id.toString();
    }

    // Si por alguna razón extrema sigue sin coincidir, mantenemos el corte.
    final verifiedDropdownId =
        int.tryParse(addressDropdownController.dropdown.value.toString()) ?? 0;

    if (verifiedDropdownId != address.id) {
      scaffoldMessenger.showSnackBar(
        SnackBar(backgroundColor: kErrorColor, content: Text(s.bSelectAddress)),
      );
      if (kDebugMode) {
        print('Serious error. Address does not correspond');
      }
      return;
    }

    // ===================== TARJETA (PayPhone) =====================
    if (paymentController.payment.type == TypesPayment.money &&
        total >= kMinPurchaseAmountCard) {
      if (kDebugMode) {
        print(
            '[BODY_CART] PayPhone flow -> total a cobrar con tarjeta: $total');
      }
      // Producto agregado temporal para pasar la validación del backend
      final payphoneProducts = [
        {
          "id": 1,
          "name": "Carrito AmaguExpress",
          "price": total, // USD
          "number": 1,
          "total": total,
          "description": "",
          "image": "",
          "note": "",
        }
      ];

      // PayPhoneWebView ahora gestiona la verificación y luego navega a ConfirmPayPhoneScreen
      // internamente (pushReplacement). Por eso aquí solo esperamos un bool de confirmación.
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PayPhoneWebView(
            amount: total,
            phoneNumber: "+593984300750",
            products: payphoneProducts,
          ),
        ),
      );

      // Si el usuario canceló o no se aprobó, no hacemos buy().
      if (confirmed != true) return;

      if (kDebugMode) {
        print(
            '[BODY_CART] PayPhone confirmado -> ejecutando buy(TypesPayment.money)');
      }

      final success = await cartSummaryController.buy(TypesPayment.money);

      if (!success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(backgroundColor: kErrorColor, content: Text(s.errUnknown)),
        );
        return;
      }

      // Navegación/refresh igual al flujo de efectivo
      navigator.popUntil((route) => route.isFirst);
      tabManController.currentScreen = 1;

      tab1Controller.load();
      tab2Controller.loadOrders();
      iconCartController.count();

      paymentController.isPaymentSelected = false;
      return;
    }
    // =================== FIN TARJETA (PayPhone) ===================

    // ====== EFECTIVO (u otros) – flujo intacto ======
    if (kDebugMode) {
      print('[BODY_CART] Efectivo/otros -> payment.type: ' +
          paymentController.payment.type.toString() +
          '  total: ' +
          total.toString());
    }
    final success =
        await cartSummaryController.buy(paymentController.payment.type);

    if (!success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(backgroundColor: kErrorColor, content: Text(s.errUnknown)),
      );
      return;
    }

    navigator.popUntil((route) => route.isFirst);

    tabManController.currentScreen = 1;

    tab1Controller.load();
    tab2Controller.loadOrders();
    iconCartController.count();

    paymentController.isPaymentSelected = false;
  }
}
