String formatBudget(int amount) {
  final sign = amount < 0 ? '-' : '';
  final absolute = amount.abs();

  if (absolute >= 1000000) {
    final millions = absolute / 1000000;
    final value = millions == millions.roundToDouble()
        ? millions.toStringAsFixed(0)
        : millions
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
    return '$sign${value}M';
  }

  return '$sign${absolute ~/ 1000}k';
}
