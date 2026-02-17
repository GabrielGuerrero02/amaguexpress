import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
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
              DetailsProducts(request: requestController.request),
            ],
          ),
        ),
      ),
    );
  }
}
