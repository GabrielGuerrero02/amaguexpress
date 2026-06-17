import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/manager/request/request_controller.dart';
import 'package:amaguexpress/src/screens/manager/request/widget/details_products.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';

class FloatingSheetBottom extends StatelessWidget {
  final RequestController requestController;

  const FloatingSheetBottom({super.key, required this.requestController});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.2,
      maxChildSize: 1,
      snap: true,
      snapSizes: const [0.4, 0.85, 1],
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.only(top: 0, right: 10, left: 10, bottom: 10),
        color: isDark ? cs.surface : Colors.white,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: SizedBox(
                  width: 60,
                  child: Divider(
                    thickness: 5,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? cs.surfaceContainerHighest : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: kPrimaryColor.withOpacity(isDark ? 0.35 : 0.22),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 58,
                      width: 58,
                      child: ClipOval(
                        child: AvatarImage(
                          image: requestController.request.store.company.image,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Icon(
                      requestController.request.payment == TypesPayment.money
                          ? Icons.credit_score_outlined
                          : Icons.payments_outlined,
                      color: kErrorColor),
                  const SizedBox(width: kDefaultPadding * 0.5),
                  Text(
                      requestController.request.payment == TypesPayment.money
                          ? S.of(context).lPayMoney
                          : S.of(context).lPayCash,
                      style: const TextStyle(color: kErrorColor)),
                  Expanded(child: Container()),
                  Expanded(child: Container()),
                  Text(
                    '${S.of(context).lTotal} ${requestController.request.total.toStringAsFixed(kCoinDecimals)} $kCoin',
                    style: TextStyle(color: cs.onSurface),
                  ),
                  const SizedBox(width: 10)
                ],
              ),
              const SizedBox(height: 10),
              if (requestController.request.status ==
                  StatusOrder.pendingStoreConfirmation)
                _PreparationApprovalCard(
                  requestController: requestController,
                ),
              if (requestController.request.status ==
                  StatusOrder.pendingStoreConfirmation)
                const SizedBox(height: 12),
              DetailsProducts(request: requestController.request),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreparationApprovalCard extends StatelessWidget {
  final RequestController requestController;

  const _PreparationApprovalCard({
    required this.requestController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest
            : kPrimaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: kPrimaryColor.withOpacity(isDark ? 0.35 : 0.22),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pedido pendiente de aprobación',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Confirma si puedes preparar este pedido antes de enviarlo a un motorizado.',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.72),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tiempo de preparación',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeButton(
                icon: Icons.remove,
                onPressed: requestController.decreasePreparationTime,
              ),
              Container(
                width: 110,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? cs.surface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kPrimaryColor.withOpacity(0.25),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${requestController.preparationTimeMinutes} min',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              _TimeButton(
                icon: Icons.add,
                onPressed: requestController.increasePreparationTime,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: requestController.inAsyncCall
                ? null
                : () async {
                    final accepted = await requestController.acceptRequest();

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          accepted
                              ? 'Pedido aceptado'
                              : 'No se pudo aceptar el pedido',
                        ),
                      ),
                    );

                    if (accepted) {
                      Navigator.of(context).pop();
                    }
                  },
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              requestController.inAsyncCall
                  ? 'Procesando...'
                  : 'Aceptar pedido',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: requestController.inAsyncCall
                ? null
                : () async {
                    final rejected = await requestController.rejectRequest();

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          rejected
                              ? 'Pedido rechazado'
                              : 'No se pudo rechazar el pedido',
                        ),
                      ),
                    );

                    if (rejected) {
                      Navigator.of(context).pop();
                    }
                  },
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Rechazar pedido'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kErrorColor,
              side: const BorderSide(color: kErrorColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _TimeButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onPressed,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: kPrimaryColor.withOpacity(0.35),
          ),
        ),
        child: Icon(icon, color: kPrimaryColor),
      ),
    );
  }
}
