import 'package:flutter/material.dart';
import 'package:everypay/domain/entities/payment_method.dart';

/// A small square avatar showing the payment method type icon with
/// the method's colour as background. Used in lists, form, and picker.
class PaymentMethodAvatar extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final double size;

  const PaymentMethodAvatar({
    super.key,
    required this.paymentMethod,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final colour = _hexToColor(paymentMethod.colourHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Icon(
        paymentMethod.type.icon,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }

  static Color _hexToColor(String hex) {
    final code = hex.replaceAll('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }
}
