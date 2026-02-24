import 'package:flutter/material.dart';
import 'package:everypay/domain/enums/expense_status.dart';

class StatusBadge extends StatelessWidget {
  final ExpenseStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      ExpenseStatus.active => (Colors.green, Icons.check_circle),
      ExpenseStatus.paused => (Colors.orange, Icons.pause_circle),
      ExpenseStatus.cancelled => (Colors.red, Icons.cancel),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          status.displayName,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
