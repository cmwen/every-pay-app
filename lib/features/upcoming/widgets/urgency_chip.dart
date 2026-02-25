import 'package:flutter/material.dart';

/// Urgency levels for upcoming payments.
enum UrgencyLevel { today, soonish, thisWeek, later }

UrgencyLevel urgencyForDays(int daysUntil) {
  if (daysUntil <= 0) return UrgencyLevel.today;
  if (daysUntil <= 3) return UrgencyLevel.soonish;
  if (daysUntil <= 7) return UrgencyLevel.thisWeek;
  return UrgencyLevel.later;
}

/// Colour-coded chip showing how many days until a payment is due.
class UrgencyChip extends StatelessWidget {
  final DateTime dueDate;

  const UrgencyChip({super.key, required this.dueDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final daysUntil = due.difference(today).inDays;

    final urgency = urgencyForDays(daysUntil);
    final (label, colour) = _labelAndColour(context, daysUntil, urgency);

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colour.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colour.withAlpha(120), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colour,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _labelAndColour(
    BuildContext context,
    int daysUntil,
    UrgencyLevel urgency,
  ) {
    final cs = Theme.of(context).colorScheme;
    return switch (urgency) {
      UrgencyLevel.today => ('Today', cs.error),
      UrgencyLevel.soonish =>
        daysUntil == 1
            ? ('Tomorrow', Colors.amber.shade700)
            : ('In $daysUntil days', Colors.amber.shade700),
      UrgencyLevel.thisWeek => ('In $daysUntil days', cs.onSurfaceVariant),
      UrgencyLevel.later => ('In $daysUntil days', cs.onSurfaceVariant),
    };
  }
}
