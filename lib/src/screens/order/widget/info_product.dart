import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/src/models/order_model.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';

class InfoProduct extends StatelessWidget {
  const InfoProduct({
    super.key,
    required this.order,
  });

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: order.products.length,
      itemBuilder: (context, index) => ListTile(
        tileColor: isDark ? cs.surface : null,
        textColor: cs.onSurface,
        iconColor: cs.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: kPrimaryColor.withOpacity(isDark ? 0.18 : 0.0),
            width: 1,
          ),
        ),
        title: Text(
          '(${order.products[index].number}) ${order.products[index].name} ${order.products[index].total.toStringAsFixed(kCoinDecimals)}',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          order.products[index].description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        trailing: AvatarImage(image: order.products[index].image),
      ),
    );
  }
}
