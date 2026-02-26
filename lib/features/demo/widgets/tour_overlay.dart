import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/features/demo/providers/demo_mode_provider.dart';
import 'package:everypay/features/demo/widgets/tour_step_config.dart';

/// Overlay that displays coach-mark tooltips during the demo tour.
///
/// Renders a dark scrim with a spotlight cutout around the target widget,
/// and a tooltip bubble with title, description, and navigation buttons.
class TourOverlay extends ConsumerWidget {
  const TourOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoModeProvider);
    if (!demoState.isTourActive) return const SizedBox.shrink();

    final registry = TourTargetRegistry.instance;
    final steps = registry.steps;
    final stepIndex = demoState.tourStep;
    if (stepIndex < 0 || stepIndex >= steps.length) return const SizedBox.shrink();

    final step = steps[stepIndex];

    // Fill the full screen so the canvas coordinate space == screen space,
    // matching renderBox.localToGlobal values exactly.
    return Positioned.fill(
      child: _TourOverlayContent(
        step: step,
        stepIndex: stepIndex,
        totalSteps: steps.length,
        onNext: () => ref.read(demoModeProvider.notifier).nextStep(),
        onSkip: () => ref.read(demoModeProvider.notifier).dismissTour(),
      ),
    );
  }
}

class _TourOverlayContent extends StatelessWidget {
  final TourStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TourOverlayContent({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    // Get target widget position
    final renderBox =
        step.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      // Target not rendered yet — skip this step
      WidgetsBinding.instance.addPostFrameCallback((_) => onNext());
      return const SizedBox.shrink();
    }

    final targetOffset = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    // Spotlight rect with padding
    const padding = 8.0;
    final spotlightRect = Rect.fromLTWH(
      targetOffset.dx - padding,
      targetOffset.dy - padding,
      targetSize.width + padding * 2,
      targetSize.height + padding * 2,
    );

    return Stack(
      children: [
        // Scrim with spotlight cutout
        Positioned.fill(
          child: GestureDetector(
            onTap: onNext,
            child: CustomPaint(
              painter: _SpotlightPainter(spotlightRect: spotlightRect),
            ),
          ),
        ),
        // Tooltip
        _buildTooltip(context, spotlightRect),
      ],
    );
  }

  Widget _buildTooltip(BuildContext context, Rect spotlightRect) {
    final screenWidth = MediaQuery.of(context).size.width;
    const tooltipMaxWidth = 300.0;
    const tooltipMargin = 16.0;
    const arrowGap = 12.0;

    // Center tooltip horizontally over spotlight, clamped to screen
    double left =
        spotlightRect.center.dx - tooltipMaxWidth / 2;
    if (left < tooltipMargin) left = tooltipMargin;
    if (left + tooltipMaxWidth > screenWidth - tooltipMargin) {
      left = screenWidth - tooltipMargin - tooltipMaxWidth;
    }

    double top;
    if (step.direction == TooltipDirection.below) {
      top = spotlightRect.bottom + arrowGap;
    } else {
      // Will be positioned from bottom
      top = spotlightRect.top - arrowGap;
    }

    final isLast = stepIndex == totalSteps - 1;
    final colorScheme = Theme.of(context).colorScheme;

    final tooltip = Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: colorScheme.surfaceContainerHighest,
      child: Container(
        width: tooltipMaxWidth,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '${stepIndex + 1} of $totalSteps',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: const Text('Skip'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onNext,
                  child: Text(isLast ? 'Done' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (step.direction == TooltipDirection.below) {
      return Positioned(
        left: left,
        top: top,
        child: tooltip,
      );
    } else {
      // Position above: use a Transform to bottom-align
      return Positioned(
        left: left,
        bottom: MediaQuery.of(context).size.height - top,
        child: tooltip,
      );
    }
  }
}

/// Paints a dark scrim with a rounded-rect cutout for the spotlight.
class _SpotlightPainter extends CustomPainter {
  final Rect spotlightRect;

  _SpotlightPainter({required this.spotlightRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()
      ..addRRect(
        RRect.fromRectAndRadius(spotlightRect, const Radius.circular(12)),
      );

    final combined = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(combined, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.spotlightRect != spotlightRect;
}
