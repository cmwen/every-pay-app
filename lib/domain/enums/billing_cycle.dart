enum BillingCycle {
  weekly,
  fortnightly,
  monthly,
  quarterly,
  biannual,
  yearly,
  custom;

  double monthlyMultiplier([int? customDays]) {
    return switch (this) {
      BillingCycle.weekly => 52 / 12,
      BillingCycle.fortnightly => 26 / 12,
      BillingCycle.monthly => 1.0,
      BillingCycle.quarterly => 1 / 3,
      BillingCycle.biannual => 1 / 6,
      BillingCycle.yearly => 1 / 12,
      BillingCycle.custom =>
        customDays != null && customDays > 0 ? 365 / (customDays * 12) : 1.0,
    };
  }

  String get displayName => switch (this) {
    BillingCycle.weekly => 'Weekly',
    BillingCycle.fortnightly => 'Fortnightly',
    BillingCycle.monthly => 'Monthly',
    BillingCycle.quarterly => 'Quarterly',
    BillingCycle.biannual => 'Bi-annual',
    BillingCycle.yearly => 'Yearly',
    BillingCycle.custom => 'Custom',
  };

  int get typicalDays => switch (this) {
    BillingCycle.weekly => 7,
    BillingCycle.fortnightly => 14,
    BillingCycle.monthly => 30,
    BillingCycle.quarterly => 91,
    BillingCycle.biannual => 182,
    BillingCycle.yearly => 365,
    BillingCycle.custom => 30,
  };
}
