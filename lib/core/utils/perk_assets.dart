String perkIdFromJson(Map? perk) {
  final raw = perk?['_id'] ?? perk?['id'];
  final rawId = raw?.toString().trim() ?? '';
  if (rawId.isNotEmpty && !_looksLikeMongoObjectId(rawId)) {
    return _normalizePerkId(rawId);
  }

  final name = perk?['name'];
  if (name is Map) {
    final nameValue = name['en'] ?? name['es'];
    final generated = _normalizePerkId(nameValue?.toString() ?? '');
    if (generated.isNotEmpty) return generated;
  }

  return '';
}

String perkAssetPath(String perkId) {
  final slug = _normalizePerkId(perkId);
  const aliases = {
    'perk-ball-and-chain': 'perk-ball-chain',
    'perk-really-stup-id': 'perk-really-stupid',
    'perk-unchanelled-fury': 'perk-unchannelled-fury',
  };
  final normalized = aliases[slug] ?? slug;
  return 'assets/images/perks/upscaled/$normalized.png';
}

String _normalizePerkId(String value) {
  var slug = value.trim().toLowerCase().replaceAll('_', '-');
  slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  slug = slug.replaceAll(RegExp(r'-+'), '-');
  slug = slug.replaceAll(RegExp(r'^-|-$'), '');
  if (slug.isEmpty) return '';
  return slug.startsWith('perk-') ? slug : 'perk-$slug';
}

bool _looksLikeMongoObjectId(String value) {
  return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value.trim());
}
