enum ExpenseStatus {
  active,
  paused,
  cancelled;

  String get displayName => switch (this) {
    ExpenseStatus.active => 'Active',
    ExpenseStatus.paused => 'Paused',
    ExpenseStatus.cancelled => 'Cancelled',
  };
}
