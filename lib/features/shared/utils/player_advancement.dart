bool hasAvailableAdvancement({required int level, required int spp}) {
  const nextCosts = {1: 3, 2: 4, 3: 6, 4: 8, 5: 10, 6: 15};
  final next = nextCosts[level] ?? 0;
  return next > 0 && spp >= next;
}
