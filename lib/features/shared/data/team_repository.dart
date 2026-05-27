import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/perk_assets.dart';
import '../../my_teams/domain/models/user_team.dart';
import '../../roster/domain/models/team.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository(dio: ref.watch(dioProvider));
});

final allPerksProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getPerks();
});

final allStarPlayersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getStarPlayers();
});

final starPlayersForTeamProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getStarPlayersForTeam(teamId);
});

final expensiveMistakesRulesProvider =
    FutureProvider<ExpensiveMistakesRules>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getExpensiveMistakesRules();
});

final injuryRulesProvider = FutureProvider<InjuryRules>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getInjuryRules();
});

final winningsRulesProvider = FutureProvider<WinningsRules>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getWinningsRules();
});

final dedicatedFansRulesProvider =
    FutureProvider<DedicatedFansRules>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getDedicatedFansRules();
});

final inducementRulesProvider = FutureProvider<InducementRules>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getInducementRules();
});

final weatherRulesProvider = FutureProvider<DiceRangeRules>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getWeatherRules();
});

final kickoffEventRulesProvider = FutureProvider<DiceRangeRules>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getKickoffEventRules();
});

final advancementRulesProvider = FutureProvider<AdvancementRules>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getAdvancementRules();
});

class AdvancementRules {
  final int maxAdvancements;
  final int maxCharacteristicImprovementsPerStat;
  final List<AdvancementCostRow> costTable;
  final List<CharacteristicImprovementResult> characteristicTable;
  final List<AdvancementValueIncrease> valueIncreases;
  final List<SkillCategoryRule> skillCategories;
  final int randomSkillRolls;
  final String randomSkillDice;
  final Map<String, String> description;

  const AdvancementRules({
    required this.maxAdvancements,
    required this.maxCharacteristicImprovementsPerStat,
    required this.costTable,
    required this.characteristicTable,
    required this.valueIncreases,
    required this.skillCategories,
    required this.randomSkillRolls,
    required this.randomSkillDice,
    required this.description,
  });

  factory AdvancementRules.fromJson(Map<String, dynamic> json) =>
      AdvancementRules(
        maxAdvancements: (json['max_advancements'] as num?)?.toInt() ?? 6,
        maxCharacteristicImprovementsPerStat:
            (json['max_characteristic_improvements_per_stat'] as num?)
                    ?.toInt() ??
                2,
        costTable: (json['cost_table'] as List<dynamic>? ?? [])
            .map((e) => AdvancementCostRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        characteristicTable:
            (json['characteristic_table'] as List<dynamic>? ?? [])
                .map((e) => CharacteristicImprovementResult.fromJson(
                    e as Map<String, dynamic>))
                .toList(),
        valueIncreases: (json['value_increases'] as List<dynamic>? ?? [])
            .map((e) =>
                AdvancementValueIncrease.fromJson(e as Map<String, dynamic>))
            .toList(),
        skillCategories: (json['skill_categories'] as List<dynamic>? ?? [])
            .map((e) => SkillCategoryRule.fromJson(e as Map<String, dynamic>))
            .toList(),
        randomSkillRolls: (json['random_skill_rolls'] as num?)?.toInt() ?? 2,
        randomSkillDice: json['random_skill_dice'] as String? ?? '2D6',
        description: ExpensiveMistakeEffect._localized(json['description']),
      );

  AdvancementCostRow? rowForAdvancement(int currentAdvancements) {
    final next = currentAdvancements + 1;
    for (final row in costTable) {
      if (row.advancementNumber == next) return row;
    }
    return null;
  }
}

class AdvancementCostRow {
  final int advancementNumber;
  final Map<String, String> levelName;
  final int randomPrimarySkill;
  final int choosePrimarySkill;
  final int chooseSecondarySkill;
  final int characteristicImprovement;

  const AdvancementCostRow({
    required this.advancementNumber,
    required this.levelName,
    required this.randomPrimarySkill,
    required this.choosePrimarySkill,
    required this.chooseSecondarySkill,
    required this.characteristicImprovement,
  });

  factory AdvancementCostRow.fromJson(Map<String, dynamic> json) =>
      AdvancementCostRow(
        advancementNumber: (json['advancement_number'] as num?)?.toInt() ?? 1,
        levelName: ExpensiveMistakeEffect._localized(json['level_name']),
        randomPrimarySkill:
            (json['random_primary_skill'] as num?)?.toInt() ?? 0,
        choosePrimarySkill:
            (json['choose_primary_skill'] as num?)?.toInt() ?? 0,
        chooseSecondarySkill:
            (json['choose_secondary_skill'] as num?)?.toInt() ?? 0,
        characteristicImprovement:
            (json['characteristic_improvement'] as num?)?.toInt() ?? 0,
      );

  int costFor(String advancementType) {
    switch (advancementType) {
      case 'random_primary_skill':
        return randomPrimarySkill;
      case 'choose_primary_skill':
        return choosePrimarySkill;
      case 'choose_secondary_skill':
        return chooseSecondarySkill;
      case 'characteristic_improvement':
        return characteristicImprovement;
      default:
        return 0;
    }
  }
}

class CharacteristicImprovementResult {
  final int minRoll;
  final int maxRoll;
  final List<String> choices;
  final Map<String, String> description;

  const CharacteristicImprovementResult({
    required this.minRoll,
    required this.maxRoll,
    required this.choices,
    required this.description,
  });

  factory CharacteristicImprovementResult.fromJson(Map<String, dynamic> json) =>
      CharacteristicImprovementResult(
        minRoll: (json['min_roll'] as num?)?.toInt() ?? 1,
        maxRoll: (json['max_roll'] as num?)?.toInt() ?? 1,
        choices:
            (json['choices'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
        description: ExpensiveMistakeEffect._localized(json['description']),
      );

  bool allows(String stat) => choices.contains(stat);
}

class AdvancementValueIncrease {
  final String advancementType;
  final int value;

  const AdvancementValueIncrease({
    required this.advancementType,
    required this.value,
  });

  factory AdvancementValueIncrease.fromJson(Map<String, dynamic> json) =>
      AdvancementValueIncrease(
        advancementType: json['advancement_type'] as String? ?? '',
        value: (json['value'] as num?)?.toInt() ?? 0,
      );
}

class SkillCategoryRule {
  final String symbol;
  final String family;
  final Map<String, String> name;

  const SkillCategoryRule({
    required this.symbol,
    required this.family,
    required this.name,
  });

  factory SkillCategoryRule.fromJson(Map<String, dynamic> json) =>
      SkillCategoryRule(
        symbol: json['symbol'] as String? ?? '',
        family: json['family'] as String? ?? '',
        name: ExpensiveMistakeEffect._localized(json['name']),
      );
}

class DiceRangeRules {
  final String id;
  final String rollDice;
  final Map<String, String> description;
  final List<DiceRangeRuleEntry> table;

  const DiceRangeRules({
    required this.id,
    required this.rollDice,
    required this.description,
    required this.table,
  });

  factory DiceRangeRules.fromJson(Map<String, dynamic> json) => DiceRangeRules(
        id: json['id'] as String? ?? '',
        rollDice: json['roll_dice'] as String? ?? '2D6',
        description: ExpensiveMistakeEffect._localized(json['description']),
        table: (json['table'] as List<dynamic>? ?? [])
            .map((e) => DiceRangeRuleEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  DiceRangeRuleEntry? resultFor(int roll) {
    for (final entry in table) {
      if (roll >= entry.minRoll && roll <= entry.maxRoll) return entry;
    }
    return null;
  }
}

class DiceRangeRuleEntry {
  final int minRoll;
  final int maxRoll;
  final String code;
  final Map<String, String> label;
  final Map<String, String> description;

  const DiceRangeRuleEntry({
    required this.minRoll,
    required this.maxRoll,
    required this.code,
    required this.label,
    required this.description,
  });

  factory DiceRangeRuleEntry.fromJson(Map<String, dynamic> json) =>
      DiceRangeRuleEntry(
        minRoll: (json['min_roll'] as num?)?.toInt() ?? 0,
        maxRoll: (json['max_roll'] as num?)?.toInt() ?? 0,
        code: json['code'] as String? ?? '',
        label: ExpensiveMistakeEffect._localized(json['label']),
        description: ExpensiveMistakeEffect._localized(json['description']),
      );

  String localizedLabel(String lang) => label[lang] ?? label['en'] ?? code;
  String localizedDescription(String lang) =>
      description[lang] ?? description['en'] ?? '';
  String get rollLabel => minRoll == maxRoll ? '$minRoll' : '$minRoll-$maxRoll';
}

class InducementRules {
  final InducementBudgetRules budget;
  final List<InducementRule> inducements;
  final List<PrayerToNuffleResult> prayersToNuffle;

  const InducementRules({
    required this.budget,
    required this.inducements,
    required this.prayersToNuffle,
  });

  factory InducementRules.fromJson(Map<String, dynamic> json) =>
      InducementRules(
        budget: InducementBudgetRules.fromJson(
            json['budget'] as Map<String, dynamic>? ?? {}),
        inducements: (json['inducements'] as List<dynamic>? ?? [])
            .map((e) => InducementRule.fromJson(e as Map<String, dynamic>))
            .toList(),
        prayersToNuffle: (json['prayers_to_nuffle'] as List<dynamic>? ?? [])
            .map(
                (e) => PrayerToNuffleResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class InducementBudgetRules {
  final int pettyCashTopUpLimit;
  final bool lowerCtvReceivesDifference;
  final bool lowerCtvReceivesOpponentTreasurySpend;
  final bool unspentPettyCashLost;
  final bool equalCtvTreasurySpendAllowed;
  final Map<String, String> description;

  const InducementBudgetRules({
    required this.pettyCashTopUpLimit,
    required this.lowerCtvReceivesDifference,
    required this.lowerCtvReceivesOpponentTreasurySpend,
    required this.unspentPettyCashLost,
    required this.equalCtvTreasurySpendAllowed,
    required this.description,
  });

  factory InducementBudgetRules.fromJson(Map<String, dynamic> json) =>
      InducementBudgetRules(
        pettyCashTopUpLimit:
            (json['petty_cash_top_up_limit'] as num?)?.toInt() ?? 50000,
        lowerCtvReceivesDifference:
            json['lower_ctv_receives_difference'] as bool? ?? true,
        lowerCtvReceivesOpponentTreasurySpend:
            json['lower_ctv_receives_opponent_treasury_spend'] as bool? ?? true,
        unspentPettyCashLost: json['unspent_petty_cash_lost'] as bool? ?? true,
        equalCtvTreasurySpendAllowed:
            json['equal_ctv_treasury_spend_allowed'] as bool? ?? false,
        description: ExpensiveMistakeEffect._localized(json['description']),
      );
}

class InducementRule {
  final String id;
  final Map<String, String> name;
  final String category;
  final int maxPerTeam;
  final int? cost;
  final List<InducementCostOption> costOptions;
  final String availability;
  final List<String> requiredSpecialRules;
  final String duration;
  final Map<String, String> description;
  final List<Map<String, String>> notes;

  const InducementRule({
    required this.id,
    required this.name,
    required this.category,
    required this.maxPerTeam,
    required this.cost,
    required this.costOptions,
    required this.availability,
    required this.requiredSpecialRules,
    required this.duration,
    required this.description,
    required this.notes,
  });

  factory InducementRule.fromJson(Map<String, dynamic> json) => InducementRule(
        id: json['id'] as String? ?? '',
        name: ExpensiveMistakeEffect._localized(json['name']),
        category: json['category'] as String? ?? 'common',
        maxPerTeam: (json['max_per_team'] as num?)?.toInt() ?? 1,
        cost: (json['cost'] as num?)?.toInt(),
        costOptions: (json['cost_options'] as List<dynamic>? ?? [])
            .map(
                (e) => InducementCostOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        availability: json['availability'] as String? ?? 'any',
        requiredSpecialRules:
            (json['required_special_rules'] as List<dynamic>? ?? [])
                .map((e) => '$e')
                .toList(),
        duration: json['duration'] as String? ?? 'game',
        description: ExpensiveMistakeEffect._localized(json['description']),
        notes: (json['notes'] as List<dynamic>? ?? [])
            .map((e) => ExpensiveMistakeEffect._localized(e))
            .toList(),
      );

  String localizedName(String lang) => name[lang] ?? name['en'] ?? id;
  String localizedDescription(String lang) =>
      description[lang] ?? description['en'] ?? '';
}

class InducementCostOption {
  final Map<String, String> label;
  final int cost;
  final String appliesTo;
  final int? maxPerTeam;

  const InducementCostOption({
    required this.label,
    required this.cost,
    required this.appliesTo,
    this.maxPerTeam,
  });

  factory InducementCostOption.fromJson(Map<String, dynamic> json) =>
      InducementCostOption(
        label: ExpensiveMistakeEffect._localized(json['label']),
        cost: (json['cost'] as num?)?.toInt() ?? 0,
        appliesTo: json['applies_to'] as String? ?? 'any',
        maxPerTeam: (json['max_per_team'] as num?)?.toInt(),
      );
}

class PrayerToNuffleResult {
  final int roll;
  final String code;
  final Map<String, String> name;
  final Map<String, String> description;

  const PrayerToNuffleResult({
    required this.roll,
    required this.code,
    required this.name,
    required this.description,
  });

  factory PrayerToNuffleResult.fromJson(Map<String, dynamic> json) =>
      PrayerToNuffleResult(
        roll: (json['roll'] as num?)?.toInt() ?? 0,
        code: json['code'] as String? ?? '',
        name: ExpensiveMistakeEffect._localized(json['name']),
        description: ExpensiveMistakeEffect._localized(json['description']),
      );

  String localizedName(String lang) {
    final localized = name[lang] ?? name['en'];
    if (localized != null && localized.trim().isNotEmpty) {
      return localized.trim();
    }
    return code
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String localizedDescription(String lang) =>
      description[lang] ?? description['en'] ?? '';
}

class DedicatedFansRules {
  final int minValue;
  final int maxValue;
  final String winRollOperator;
  final String lossRollOperator;
  final Map<String, String> description;

  const DedicatedFansRules({
    required this.minValue,
    required this.maxValue,
    required this.winRollOperator,
    required this.lossRollOperator,
    required this.description,
  });

  factory DedicatedFansRules.fromJson(Map<String, dynamic> json) =>
      DedicatedFansRules(
        minValue: (json['min_value'] as num?)?.toInt() ?? 1,
        maxValue: (json['max_value'] as num?)?.toInt() ?? 7,
        winRollOperator: json['win_roll_operator'] as String? ?? '>=',
        lossRollOperator: json['loss_roll_operator'] as String? ?? '<',
        description: ExpensiveMistakeEffect._localized(json['description']),
      );

  int nextValue({
    required int current,
    required int? roll,
    required bool won,
    required bool lost,
  }) {
    final clamped = current.clamp(minValue, maxValue).toInt();
    if (won && roll != null && roll >= clamped) {
      return (clamped + 1).clamp(minValue, maxValue).toInt();
    }
    if (lost && roll != null && roll < clamped) {
      return (clamped - 1).clamp(minValue, maxValue).toInt();
    }
    return clamped;
  }
}

class WinningsRules {
  final int fanAttendanceDivisor;
  final int noStallingBonus;
  final int goldMultiplier;
  final Map<String, String> description;

  const WinningsRules({
    required this.fanAttendanceDivisor,
    required this.noStallingBonus,
    required this.goldMultiplier,
    required this.description,
  });

  factory WinningsRules.fromJson(Map<String, dynamic> json) => WinningsRules(
        fanAttendanceDivisor:
            (json['fan_attendance_divisor'] as num?)?.toInt() ?? 2,
        noStallingBonus: (json['no_stalling_bonus'] as num?)?.toInt() ?? 1,
        goldMultiplier: (json['gold_multiplier'] as num?)?.toInt() ?? 10000,
        description: ExpensiveMistakeEffect._localized(json['description']),
      );

  double fanBase(int teamFanFactor, int opponentFanFactor) {
    return (teamFanFactor + opponentFanFactor) / fanAttendanceDivisor;
  }

  int calculate({
    required int teamFanFactor,
    required int opponentFanFactor,
    required int touchdowns,
    required bool stalling,
  }) {
    final stallBonus = stalling ? 0 : noStallingBonus;
    return ((fanBase(teamFanFactor, opponentFanFactor) +
                touchdowns +
                stallBonus) *
            goldMultiplier)
        .round();
  }
}

class ExpensiveMistakesRules {
  final int minTreasury;
  final List<ExpensiveMistakeBand> bands;
  final Map<String, ExpensiveMistakeEffect> effects;

  const ExpensiveMistakesRules({
    required this.minTreasury,
    required this.bands,
    required this.effects,
  });

  factory ExpensiveMistakesRules.fromJson(Map<String, dynamic> json) {
    final effectList = (json['effects'] as List<dynamic>? ?? [])
        .map((e) => ExpensiveMistakeEffect.fromJson(e as Map<String, dynamic>))
        .toList();
    return ExpensiveMistakesRules(
      minTreasury: (json['min_treasury'] as num?)?.toInt() ?? 100000,
      bands: (json['bands'] as List<dynamic>? ?? [])
          .map((e) => ExpensiveMistakeBand.fromJson(e as Map<String, dynamic>))
          .toList(),
      effects: {for (final effect in effectList) effect.code: effect},
    );
  }

  String? resultFor(int treasury, int roll) {
    if (treasury < minTreasury) return null;
    final clampedRoll = roll.clamp(1, 6).toInt();
    for (final band in bands) {
      final upper = band.maxTreasury;
      if (treasury >= band.minTreasury &&
          (upper == null || treasury <= upper)) {
        return band.results[clampedRoll - 1];
      }
    }
    return null;
  }
}

class ExpensiveMistakeBand {
  final int minTreasury;
  final int? maxTreasury;
  final List<String> results;

  const ExpensiveMistakeBand({
    required this.minTreasury,
    required this.maxTreasury,
    required this.results,
  });

  factory ExpensiveMistakeBand.fromJson(Map<String, dynamic> json) =>
      ExpensiveMistakeBand(
        minTreasury: (json['min_treasury'] as num?)?.toInt() ?? 0,
        maxTreasury: (json['max_treasury'] as num?)?.toInt(),
        results:
            (json['results'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      );
}

class ExpensiveMistakeEffect {
  final String code;
  final Map<String, String> label;
  final Map<String, String> description;
  final String calculation;
  final List<String> requiredDice;

  const ExpensiveMistakeEffect({
    required this.code,
    required this.label,
    required this.description,
    required this.calculation,
    required this.requiredDice,
  });

  factory ExpensiveMistakeEffect.fromJson(Map<String, dynamic> json) =>
      ExpensiveMistakeEffect(
        code: json['code'] as String? ?? '',
        label: _localized(json['label']),
        description: _localized(json['description']),
        calculation: json['calculation'] as String? ?? 'none',
        requiredDice: (json['required_dice'] as List<dynamic>? ?? [])
            .map((e) => '$e')
            .toList(),
      );

  String localizedLabel(String lang) => label[lang] ?? label['en'] ?? code;

  String localizedDescription(String lang) =>
      description[lang] ?? description['en'] ?? '';

  static Map<String, String> _localized(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, val) => MapEntry('$key', '$val'));
  }
}

class InjuryRules {
  final List<DiceTableEntry> injuryTable;
  final List<DiceTableEntry> stuntyInjuryTable;
  final List<CasualtyTableEntry> casualtyTable;
  final List<LastingInjuryTableEntry> lastingInjuryTable;

  const InjuryRules({
    required this.injuryTable,
    required this.stuntyInjuryTable,
    required this.casualtyTable,
    required this.lastingInjuryTable,
  });

  factory InjuryRules.fromJson(Map<String, dynamic> json) => InjuryRules(
        injuryTable: (json['injury_table'] as List<dynamic>? ?? [])
            .map((e) => DiceTableEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        stuntyInjuryTable: (json['stunty_injury_table'] as List<dynamic>? ?? [])
            .map((e) => DiceTableEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        casualtyTable: (json['casualty_table'] as List<dynamic>? ?? [])
            .map((e) => CasualtyTableEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastingInjuryTable:
            (json['lasting_injury_table'] as List<dynamic>? ?? [])
                .map((e) =>
                    LastingInjuryTableEntry.fromJson(e as Map<String, dynamic>))
                .toList(),
      );

  CasualtyTableEntry? casualtyResultFor(int roll) {
    for (final entry in casualtyTable) {
      if (roll >= entry.minRoll && roll <= entry.maxRoll) return entry;
    }
    return null;
  }

  LastingInjuryTableEntry? lastingResultFor(int roll) {
    for (final entry in lastingInjuryTable) {
      if (roll >= entry.minRoll && roll <= entry.maxRoll) return entry;
    }
    return null;
  }
}

class DiceTableEntry {
  final int minRoll;
  final int maxRoll;
  final String code;
  final Map<String, String> label;
  final Map<String, String> description;

  const DiceTableEntry({
    required this.minRoll,
    required this.maxRoll,
    required this.code,
    required this.label,
    required this.description,
  });

  factory DiceTableEntry.fromJson(Map<String, dynamic> json) => DiceTableEntry(
        minRoll: (json['min_roll'] as num?)?.toInt() ?? 0,
        maxRoll: (json['max_roll'] as num?)?.toInt() ?? 0,
        code: json['code'] as String? ?? '',
        label: ExpensiveMistakeEffect._localized(json['label']),
        description: ExpensiveMistakeEffect._localized(json['description']),
      );

  String localizedLabel(String lang) => label[lang] ?? label['en'] ?? code;
  String localizedDescription(String lang) =>
      description[lang] ?? description['en'] ?? '';
  String get rangeLabel =>
      minRoll == maxRoll ? '$minRoll' : '$minRoll-$maxRoll';
}

class CasualtyTableEntry extends DiceTableEntry {
  final String playerStatus;
  final List<String> injuryCodes;
  final bool requiresLastingInjuryRoll;

  const CasualtyTableEntry({
    required super.minRoll,
    required super.maxRoll,
    required super.code,
    required super.label,
    required super.description,
    required this.playerStatus,
    required this.injuryCodes,
    required this.requiresLastingInjuryRoll,
  });

  factory CasualtyTableEntry.fromJson(Map<String, dynamic> json) =>
      CasualtyTableEntry(
        minRoll: (json['min_roll'] as num?)?.toInt() ?? 0,
        maxRoll: (json['max_roll'] as num?)?.toInt() ?? 0,
        code: json['code'] as String? ?? '',
        label: ExpensiveMistakeEffect._localized(json['label']),
        description: ExpensiveMistakeEffect._localized(json['description']),
        playerStatus: json['player_status'] as String? ?? 'healthy',
        injuryCodes: (json['injury_codes'] as List<dynamic>? ?? [])
            .map((e) => '$e')
            .toList(),
        requiresLastingInjuryRoll:
            json['requires_lasting_injury_roll'] as bool? ?? false,
      );
}

class LastingInjuryTableEntry extends DiceTableEntry {
  final String stat;
  final String reductionLabel;

  const LastingInjuryTableEntry({
    required super.minRoll,
    required super.maxRoll,
    required super.code,
    required super.label,
    required super.description,
    required this.stat,
    required this.reductionLabel,
  });

  factory LastingInjuryTableEntry.fromJson(Map<String, dynamic> json) =>
      LastingInjuryTableEntry(
        minRoll: (json['min_roll'] as num?)?.toInt() ?? 0,
        maxRoll: (json['max_roll'] as num?)?.toInt() ?? 0,
        code: json['code'] as String? ?? '',
        label: ExpensiveMistakeEffect._localized(json['label']),
        description: ExpensiveMistakeEffect._localized(json['description']),
        stat: json['stat'] as String? ?? '',
        reductionLabel: json['reduction_label'] as String? ?? '',
      );
}

class TeamRepository {
  final Dio _dio;

  TeamRepository({required Dio dio}) : _dio = dio;

  Future<List<Team>> getMyTeams() async {
    try {
      final response = await _dio.get('/teams/my');
      return (response.data as List)
          .map((json) => Team.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Team> getTeam(String teamId) async {
    try {
      final response = await _dio.get('/user-teams/$teamId');
      return Team.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> createUserTeam({
    required String name,
    required String baseRosterId,
    List<Map<String, dynamic>> players = const [],
    int rerolls = 0,
    int cheerleaders = 0,
    int assistantCoaches = 0,
    bool apothecary = false,
    int dedicatedFans = 1,
  }) async {
    try {
      final response = await _dio.post('/user-teams/', data: {
        'name': name,
        'base_roster_id': baseRosterId,
        'players': players,
        'rerolls': rerolls,
        'cheerleaders': cheerleaders,
        'assistant_coaches': assistantCoaches,
        'apothecary': apothecary,
        'dedicated_fans': dedicatedFans,
      });
      return response.data['id'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> hirePlayer(
    String teamId, {
    required String baseType,
    String? name,
    int? number,
    bool temporaryForMatch = false,
    String? temporaryMatchId,
  }) async {
    try {
      await _dio.post('/user-teams/$teamId/players', data: {
        'base_type': baseType,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (number != null) 'number': number,
        if (temporaryForMatch) 'temporary_for_match': true,
        if (temporaryMatchId != null) 'temporary_match_id': temporaryMatchId,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> hireStarPlayer(
    String teamId, {
    required String starPlayerId,
    String? name,
    int? number,
    bool temporaryForMatch = false,
    String? temporaryMatchId,
  }) async {
    try {
      await _dio.post('/user-teams/$teamId/players/star', data: {
        'star_player_id': starPlayerId,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (number != null) 'number': number,
        if (temporaryForMatch) 'temporary_for_match': true,
        if (temporaryMatchId != null) 'temporary_match_id': temporaryMatchId,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserTeamDetail> patchTeamStaff(
    String teamId, {
    String? name,
    int? rerolls,
    int? cheerleaders,
    int? assistantCoaches,
    bool? apothecary,
    int? fanFactor,
    int? dedicatedFans,
    int? treasury,
    String? notes,
  }) async {
    try {
      final response = await _dio.patch('/user-teams/$teamId', data: {
        if (name != null) 'name': name,
        if (rerolls != null) 'rerolls': rerolls,
        if (cheerleaders != null) 'cheerleaders': cheerleaders,
        if (assistantCoaches != null) 'assistant_coaches': assistantCoaches,
        if (apothecary != null) 'apothecary': apothecary,
        if (fanFactor != null) 'fan_factor': fanFactor,
        if (dedicatedFans != null) 'dedicated_fans': dedicatedFans,
        if (treasury != null) 'treasury': treasury,
        if (notes != null) 'notes': notes,
      });
      return UserTeamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<InjuryRules> getInjuryRules() async {
    try {
      final response = await _dio.get('/rules/injuries');
      return InjuryRules.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<WinningsRules> getWinningsRules() async {
    try {
      final response = await _dio.get('/rules/winnings');
      return WinningsRules.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DedicatedFansRules> getDedicatedFansRules() async {
    try {
      final response = await _dio.get('/rules/dedicated-fans');
      return DedicatedFansRules.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<InducementRules> getInducementRules() async {
    try {
      final response = await _dio.get('/rules/inducements');
      return InducementRules.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DiceRangeRules> getWeatherRules() async {
    try {
      final response = await _dio.get('/rules/weather');
      return DiceRangeRules.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DiceRangeRules> getKickoffEventRules() async {
    try {
      final response = await _dio.get('/rules/kickoff-events');
      return DiceRangeRules.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdvancementRules> getAdvancementRules() async {
    try {
      final response = await _dio.get('/rules/advancements');
      return AdvancementRules.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> fireUserPlayer(String teamId, String playerId) async {
    try {
      await _dio.delete('/user-teams/$teamId/players/$playerId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserTeamDetail> updatePlayer(
    String teamId,
    String playerId, {
    String? name,
    int? number,
    String? status,
    String? injuryCategory,
    String? injuryNote,
    int? lastingInjuryRoll,
  }) async {
    try {
      final response = await _dio.patch(
        '/user-teams/$teamId/players/$playerId',
        data: {
          if (name != null) 'name': name,
          if (number != null) 'number': number,
          if (status != null) 'status': status,
          if (injuryCategory != null) 'injury_category': injuryCategory,
          if (injuryNote != null) 'injury_note': injuryNote,
          if (lastingInjuryRoll != null)
            'lasting_injury_roll': lastingInjuryRoll,
        },
      );
      return UserTeamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<UserTeamSummary>> getUserTeams() async {
    try {
      final response = await _dio.get('/user-teams/');
      return (response.data as List)
          .map((e) => UserTeamSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserTeamDetail> getUserTeamDetail(String teamId) async {
    try {
      final response = await _dio.get('/user-teams/$teamId');
      return UserTeamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteUserTeam(String teamId) async {
    try {
      await _dio.delete('/user-teams/$teamId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ExpensiveMistakesRules> getExpensiveMistakesRules() async {
    try {
      final response = await _dio.get('/rules/expensive-mistakes');
      return ExpensiveMistakesRules.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Team> updateTeam(String teamId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch('/teams/$teamId', data: updates);
      return Team.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Character> addCharacter(
      String teamId, String positionId, String name) async {
    try {
      final response = await _dio.post('/teams/$teamId/characters', data: {
        'position_id': positionId,
        'name': name,
      });
      return Character.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> removeCharacter(String teamId, String characterId) async {
    try {
      await _dio.delete('/teams/$teamId/characters/$characterId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Character> updateCharacter(
    String teamId,
    String characterId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _dio.patch(
        '/teams/$teamId/characters/$characterId',
        data: updates,
      );
      return Character.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Character> addSkill(
      String teamId, String characterId, String skillId) async {
    try {
      final response = await _dio.post(
        '/teams/$teamId/characters/$characterId/skills',
        data: {'skill_id': skillId},
      );
      return Character.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> buyReroll(String teamId) async {
    try {
      await _dio.post('/teams/$teamId/reroll');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> buyApothecary(String teamId) async {
    try {
      await _dio.post('/teams/$teamId/apothecary');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> buyStaff(String teamId, String staffType) async {
    try {
      await _dio.post('/teams/$teamId/staff', data: {'type': staffType});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<BaseTeam>> getBaseTeams() async {
    try {
      final response = await _dio.get('/base-rosters/');
      final teams = (response.data as List)
          .map((json) => BaseTeam.fromJson(json))
          .toList();
      teams.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return teams;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BaseTeam> getBaseTeamDetail(String rosterId) async {
    try {
      final response = await _dio.get('/base-rosters/$rosterId');
      return BaseTeam.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPerks() async {
    try {
      final response = await _dio.get('/perks/');
      final data = response.data['data'] as List;
      return data.cast<Map<String, dynamic>>().map((perk) {
        final normalized = Map<String, dynamic>.from(perk);
        final canonicalId = perkIdFromJson(normalized);
        normalized['_id'] = canonicalId;
        normalized['id'] = canonicalId;
        return normalized;
      }).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getStarPlayers() async {
    try {
      final response = await _dio.get('/star-players/');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAllStarPlayerDetails() async {
    try {
      final response = await _dio.get('/star-players/details');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getStarPlayer(String starPlayerId) async {
    try {
      final response = await _dio.get('/star-players/$starPlayerId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getStarPlayersForTeam(
      String teamId) async {
    try {
      final response = await _dio.get('/star-players/team/$teamId');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> createTactic(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/tactics/', data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyTactics() async {
    try {
      final response = await _dio.get('/tactics/');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getTactic(String tacticId) async {
    try {
      final response = await _dio.get('/tactics/$tacticId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> updateTactic(
      String tacticId, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch('/tactics/$tacticId', data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteTactic(String tacticId) async {
    try {
      await _dio.delete('/tactics/$tacticId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserTeamDetail> addPerkToPlayer(
    String teamId,
    String playerId, {
    required String perkId,
    required String perkName,
    String? category,
  }) async {
    try {
      final response = await _dio.post(
        '/user-teams/$teamId/players/$playerId/perks',
        data: {
          'perk_id': perkId,
          'perk_name': perkName,
          if (category != null) 'category': category,
        },
      );
      return UserTeamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserTeamDetail> applyPlayerAdvancement(
    String teamId,
    String playerId, {
    required String advancementType,
    String? perkId,
    String? characteristic,
    int? characteristicRoll,
  }) async {
    try {
      final response = await _dio.post(
        '/user-teams/$teamId/players/$playerId/advancements',
        data: {
          'advancement_type': advancementType,
          if (perkId != null) 'perk_id': perkId,
          if (characteristic != null) 'characteristic': characteristic,
          if (characteristicRoll != null)
            'characteristic_roll': characteristicRoll,
        },
      );
      return UserTeamDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
