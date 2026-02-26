import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the app is in demo mode and the current tour step.
///
/// Tour steps:
///   0 = summary card
///   1 = due soon section
///   2 = first expense item
///   3 = FAB (add button)
///   4 = stats nav tab
///  -1 = tour finished / not active
final demoModeProvider = NotifierProvider<DemoModeNotifier, DemoModeState>(
  DemoModeNotifier.new,
);

class DemoModeState {
  final bool isActive;
  final int tourStep; // -1 means tour completed or not started
  final bool tourDismissed;

  const DemoModeState({
    this.isActive = false,
    this.tourStep = -1,
    this.tourDismissed = false,
  });

  bool get isTourActive => isActive && tourStep >= 0 && !tourDismissed;

  DemoModeState copyWith({
    bool? isActive,
    int? tourStep,
    bool? tourDismissed,
  }) {
    return DemoModeState(
      isActive: isActive ?? this.isActive,
      tourStep: tourStep ?? this.tourStep,
      tourDismissed: tourDismissed ?? this.tourDismissed,
    );
  }
}

class DemoModeNotifier extends Notifier<DemoModeState> {
  static const int totalSteps = 5;

  @override
  DemoModeState build() => const DemoModeState();

  /// Activate demo mode and start the guided tour.
  void activate() {
    state = const DemoModeState(
      isActive: true,
      tourStep: 0,
      tourDismissed: false,
    );
  }

  /// Deactivate demo mode entirely — returns to real data.
  void deactivate() {
    state = const DemoModeState();
  }

  /// Advance to the next tour step. If at the last step, mark tour as done.
  void nextStep() {
    if (state.tourStep < totalSteps - 1) {
      state = state.copyWith(tourStep: state.tourStep + 1);
    } else {
      state = state.copyWith(tourStep: -1, tourDismissed: true);
    }
  }

  /// Skip/dismiss the tour but stay in demo mode.
  void dismissTour() {
    state = state.copyWith(tourStep: -1, tourDismissed: true);
  }
}
