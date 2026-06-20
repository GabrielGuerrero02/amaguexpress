import 'package:flutter/material.dart';
import 'package:amaguexpress/src/widgets/avatar_image.dart';

class OrderCompanyLogo extends StatelessWidget {
  const OrderCompanyLogo({
    super.key,
    required this.image,
    required this.height,
    this.width = 165,
    this.logoSize = 135,
  });

  final String image;
  final double height;
  final double width;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: AvatarImage(
          image: image,
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
