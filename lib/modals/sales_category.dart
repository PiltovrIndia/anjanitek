class SalesCategoryTarget {
  final String name;      // e.g. "VCL", "ATL", "COLLECTION"
  final double target;    // monthly target
  final double achieved;  // achieved so far

  const SalesCategoryTarget({
    required this.name,
    required this.target,
    required this.achieved,
  });

  double get progress => target == 0 ? 0 : (achieved / target).clamp(0, 1);
}

class MonthlySalesTarget {
  final String monthLabel;        // "October 2025"
  final double targetAmount;      // e.g. 30_00_000
  final double achievedAmount;    // e.g. 18_20_000
  final int totalDaysInMonth;     // 31
  final int dayOfMonth;           // today’s date in that month
  final List<SalesCategoryTarget> categories;

  const MonthlySalesTarget({
    required this.monthLabel,
    required this.targetAmount,
    required this.achievedAmount,
    required this.totalDaysInMonth,
    required this.dayOfMonth,
    this.categories = const [],
  });

  double get progress =>
      targetAmount == 0 ? 0 : (achievedAmount / targetAmount).clamp(0, 1);

  double get pending => (targetAmount - achievedAmount).clamp(0, targetAmount);

  int get daysLeft => (totalDaysInMonth - dayOfMonth).clamp(0, totalDaysInMonth);

  double get dailyNeeded =>
      daysLeft == 0 ? 0 : pending / daysLeft;

  String get statusLabel {
    if (progress >= expectedProgress + 0.1) return "Ahead";
    if (progress >= expectedProgress - 0.05) return "On Track";
    if (progress >= expectedProgress - 0.15) return "Behind";
    return "Critical";
  }

  // Expected progress based on calendar day
  double get expectedProgress =>
      totalDaysInMonth == 0 ? 0 : (dayOfMonth / totalDaysInMonth).clamp(0, 1);
}
