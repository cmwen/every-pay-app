import 'dart:math';
import 'package:flutter/material.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/features/stats/providers/monthly_stats_provider.dart';

class CategoryPieChart extends StatelessWidget {
  final List<CategorySpend> data;
  final double size;

  const CategoryPieChart({super.key, required this.data, this.size = 200});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: size,
        child: const Center(child: Text('No data')),
      );
    }

    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(painter: _PieChartPainter(data: data)),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<CategorySpend> data;

  _PieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final innerRadius = radius * 0.6;

    double startAngle = -pi / 2;

    for (final item in data) {
      final sweepAngle = (item.percentage / 100) * 2 * pi;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = categoryColor(item.categoryColour);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw inner circle for donut effect
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    // We'll let the theme handle this - use a slightly transparent version
    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
