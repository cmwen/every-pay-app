import 'package:flutter/material.dart';

/// Defines a single step in the demo tour.
class TourStep {
  final String title;
  final String description;
  final GlobalKey targetKey;
  final TooltipDirection direction;

  const TourStep({
    required this.title,
    required this.description,
    required this.targetKey,
    this.direction = TooltipDirection.below,
  });
}

enum TooltipDirection { above, below }

/// Registry for tour target GlobalKeys. Widgets register their keys here
/// so the tour overlay can find them.
class TourTargetRegistry {
  TourTargetRegistry._();
  static final instance = TourTargetRegistry._();

  final summaryCardKey = GlobalKey(debugLabel: 'tour-summary-card');
  final dueSoonKey = GlobalKey(debugLabel: 'tour-due-soon');
  final firstExpenseKey = GlobalKey(debugLabel: 'tour-first-expense');
  final fabKey = GlobalKey(debugLabel: 'tour-fab');
  final statsNavKey = GlobalKey(debugLabel: 'tour-stats-nav');

  List<TourStep> get steps => [
        TourStep(
          title: 'Monthly Spending',
          description:
              'Your total monthly cost at a glance, with a trend vs. last month.',
          targetKey: summaryCardKey,
          direction: TooltipDirection.below,
        ),
        TourStep(
          title: 'Due Soon',
          description:
              'Upcoming payments in the next 7 days. Tap "See all" for the full calendar.',
          targetKey: dueSoonKey,
          direction: TooltipDirection.below,
        ),
        TourStep(
          title: 'Your Subscriptions',
          description:
              'Each row shows name, category, cycle, and cost. Tap for details.',
          targetKey: firstExpenseKey,
          direction: TooltipDirection.below,
        ),
        TourStep(
          title: 'Add Expense',
          description:
              'Tap here to add a new subscription. Pick from popular services or enter manually.',
          targetKey: fabKey,
          direction: TooltipDirection.above,
        ),
        TourStep(
          title: 'Statistics & Insights',
          description:
              'Charts break down spending by category and month. Swipe between tabs.',
          targetKey: statsNavKey,
          direction: TooltipDirection.above,
        ),
      ];
}
