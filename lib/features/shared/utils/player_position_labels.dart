import '../../my_teams/domain/models/user_team.dart';
import '../../roster/domain/models/team.dart';

BasePosition? findBasePositionForPlayer(BaseTeam? roster, UserPlayer player) {
  if (roster == null) return null;

  final playerKeys = <String>{
    _positionKey(player.baseType),
    _positionKey(player.positionLabel),
  }..remove('');

  for (final candidate in roster.positions) {
    final candidateKeys = <String>{
      _positionKey(candidate.id),
      _positionKey(candidate.name),
      if (candidate.position != null) _positionKey(candidate.position!),
    }..remove('');

    if (candidateKeys.intersection(playerKeys).isNotEmpty) {
      return candidate;
    }
  }

  return null;
}

String localizedPlayerPosition(
  UserPlayer player, {
  required String lang,
  BaseTeam? roster,
}) {
  final position = findBasePositionForPlayer(roster, player);
  final raw = position?.position ?? position?.name ?? player.positionLabel;
  return localizedPositionText(raw, lang);
}

String localizedPositionText(String raw, String lang) {
  final text = raw.trim();
  if (text.isEmpty) return text;

  final slashParts = text.split(' / ');
  if (slashParts.length >= 2) {
    return (lang == 'es' ? slashParts.last : slashParts.first).trim();
  }

  final normalized = text.toLowerCase().trim();
  if (lang == 'es') {
    const translatedRoles = {
      'lineman': 'Línea',
      'linewoman': 'Línea',
      'thrower': 'Lanzador',
      'catcher': 'Receptor',
      'runner': 'Corredor',
      'blocker': 'Bloqueador',
      'blitzer': 'Blitzer',
      'big guy': 'Tipo Grande',
      'positional': 'Posicional',
      'star player': 'Jugador Estrella',
    };

    final translated = translatedRoles[normalized];
    if (translated != null) return translated;
  }

  if (normalized.startsWith('star_')) {
    return lang == 'es' ? 'Jugador Estrella' : 'Star Player';
  }

  return _titleFromId(text);
}

String _positionKey(String value) =>
    value.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '');

String _titleFromId(String value) {
  final words = value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
