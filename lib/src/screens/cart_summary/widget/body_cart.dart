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
import 'package:amaguexpress/src/screens/cart_summary/confirm_payphone_screen.dart';

class BodyCart extends StatelessWidget {
  const BodyCart({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final paymentController = Provider.of<PaymentDropdownController>(context);
    final cartSummaryController = Provider.of<CartSummaryController>(context);
    final double width = MediaQuery.of(context).size.width;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: AddressDropdown(isScreenMain: false)),
        const SliverToBoxAdapter(child: PaymentDropdown()),
        if (cartSummaryController.money > 0)
          SliverToBoxAdapter(child: MoneyInput(cartSummaryController.money)),
        SliverToBoxAdapter(
            child: CompanyProducts(
                cartSummaryController: cartSummaryController, width: width)),
        SliverToBoxAdapter(
            child: _paymentMethodButton(
                context, paymentController, cartSummaryController)),
      ],
    );
  }

  Widget _paymentMethodButton(
      BuildContext context,
      PaymentDropdownController paymentController,
      CartSummaryController cartSummaryController) {
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
                context, paymentController, cartSummaryController, total);
          },
        );

      case TypesPayment.cash:
        return PrimaryButton(
          color: Theme.of(context).colorScheme.primary,
          text:
              "${S.of(context).bPay} ${total.toStringAsFixed(kCoinDecimals)} $kCoin",
          icon: Icons.payments_outlined,
          onPressed: () {
            _onPressedBuy(
                context, paymentController, cartSummaryController, total);
          },
        );
      default:
        return PrimaryButton(
          color: Theme.of(context).colorScheme.primary,
          text:
              "${S.of(context).bPay} ${total.toStringAsFixed(kCoinDecimals)} $kCoin",
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: kErrorColor,
              content: Text(S.of(context).lselectPayment),
            ));
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
      scaffoldMessenger.showSnackBar(SnackBar(
          backgroundColor: kErrorColor, content: Text(s.bSelectAddress)));
      return;
    }

    // ✅ Mantienes tu validación estricta de dirección (si no coincide, se corta)
    if (address.id !=
        int.parse(addressDropdownController.dropdown.value.toString())) {
      scaffoldMessenger.showSnackBar(SnackBar(
          backgroundColor: kErrorColor, content: Text(s.bSelectAddress)));
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

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PayPhoneWebView(
            amount: total,
            phoneNumber: "+593984300750",
            products: payphoneProducts,
          ),
        ),
      );

      if (result == null ||
          result['transactionId'] == null ||
          result['clientTxId'] == null) {
        scaffoldMessenger.showSnackBar(SnackBar(
          backgroundColor: kErrorColor,
          content: Text(s.errUnknown),
        ));
        return;
      }
      if (kDebugMode) {
        print('[BODY_CART] WebView ok -> txId: ' +
            result['transactionId'].toString() +
            '  clientTxId: ' +
            result['clientTxId'].toString());
      }

      final String transactionId = result['transactionId'].toString();
      final String clientTxId = result['clientTxId'].toString();

      // Abre la pantalla de confirmación: POST /confirm y luego buy(...)
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmPayPhoneScreen(
            transactionId: transactionId,
            clientTxId: clientTxId,
          ),
        ),
      );

      // Si la pantalla de confirmación decide devolver true, refrescamos vistas aquí mismo
      // (si ya manejó la navegación internamente, esto simplemente no hará nada visible).
      if (confirmed == true) {
        if (kDebugMode) {
          print(
              '[BODY_CART] ConfirmPayPhoneScreen -> confirmed=true, refrescando UI');
        }
        // Refresca contadores y pestañas, sin navegar a otra ruta aquí.
        tab1Controller.load();
        tab2Controller.loadOrders();
        iconCartController.count();
        paymentController.isPaymentSelected = false;
      }

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
