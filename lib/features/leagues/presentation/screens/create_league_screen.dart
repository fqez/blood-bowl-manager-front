import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/data/repositories.dart';
import '../../domain/models/league_summary.dart';

class CreateLeagueScreen extends ConsumerStatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  ConsumerState<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends ConsumerState<CreateLeagueScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String _format = 'round_robin';
  int _maxTeams = 8;
  int _startingBudget = 1000000;
  bool _resurrection = false;
  bool _inducements = true;
  bool _spiralingExpenses = true;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Submit ──

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final league = await ref.read(leagueRepositoryProvider).createLeagueFull(
            name: _nameController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            format: _format,
            maxTeams: _maxTeams,
            startingBudget: _startingBudget,
            resurrection: _resurrection,
            inducements: _inducements,
            spiralingExpenses: _spiralingExpenses,
          );
      if (mounted) _showInviteCodeDialog(league);
    } catch (e) {
      if (mounted) {
        final lang = ref.read(localeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trf(lang, 'createLeague.error', {'e': e.toString()})),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInviteCodeDialog(LeagueSummaryModel league) {
    final code = league.inviteCode ?? '—';
    final lang = ref.read(localeProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              color: AppColors.success),
          const SizedBox(width: 10),
          Text(tr(lang, 'createLeague.created'),
              style: TextStyle(color: AppColors.textPrimary)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(lang, 'createLeague.shareCode'),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: AppColors.accent,
                        fontFamily: 'monospace'),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(tr(lang, 'createLeague.codeCopied')),
                            duration: const Duration(seconds: 1)),
                      );
                    },
                    icon: Icon(PhosphorIcons.copy(PhosphorIconsStyle.regular),
                        color: AppColors.accent),
                    tooltip: tr(lang, 'createLeague.copyCode'),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/leagues');
            },
            child: Text(tr(lang, 'createLeague.goToLeagues'),
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/league/${league.id}');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(tr(lang, 'createLeague.viewLeague')),
          ),
        ],
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 80 : 16, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(tr(lang, 'createLeague.info')),
                        const SizedBox(height: 12),
                        _buildNameField(lang),
                        const SizedBox(height: 14),
                        _buildDescField(lang),
                        const SizedBox(height: 28),
                        _sectionTitle(tr(lang, 'createLeague.format')),
                        const SizedBox(height: 12),
                        _buildFormatSelector(lang),
                        const SizedBox(height: 20),
                        _buildMaxTeamsSlider(lang),
                        const SizedBox(height: 28),
                        _sectionTitle(tr(lang, 'createLeague.rules')),
                        const SizedBox(height: 12),
                        _buildBudgetChips(lang),
                        const SizedBox(height: 16),
                        _buildRuleToggle(
                            'Resurrecciones',
                            'Los fallecidos vuelven sin consecuencias al final del partido.',
                            _resurrection,
                            (v) => setState(() => _resurrection = v),
                            PhosphorIcons.heartbeat(PhosphorIconsStyle.bold)),
                        const SizedBox(height: 8),
                        _buildRuleToggle(
                            'Inducements',
                            'Los equipos pueden comprar refuerzos antes del partido.',
                            _inducements,
                            (v) => setState(() => _inducements = v),
                            PhosphorIcons.coins(PhosphorIconsStyle.bold)),
                        const SizedBox(height: 8),
                        _buildRuleToggle(
                            'Gastos Espirales',
                            'Los equipos mejores gastan más en mantenimiento de plantilla.',
                            _spiralingExpenses,
                            (v) => setState(() => _spiralingExpenses = v),
                            PhosphorIcons.trendUp(PhosphorIconsStyle.bold)),
                        const SizedBox(height: 32),
                        _buildSubmitButton(lang),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final lang = ref.watch(localeProvider);
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.go('/leagues'),
                icon: Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                    color: AppColors.textSecondary),
              ),
              Text(
                tr(lang, 'createLeague.create'),
                style: TextStyle(
                  fontFamily: AppTextStyles.displayFont,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1),
      );

  Widget _buildNameField(String lang) => TextFormField(
        controller: _nameController,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: _inputDecoration(tr(lang, 'createLeague.leagueName'),
            required: true),
        maxLength: 100,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
          if (v.trim().length < 3) return 'Mínimo 3 caracteres';
          return null;
        },
      );

  Widget _buildDescField(String lang) => TextFormField(
        controller: _descController,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: _inputDecoration(tr(lang, 'createLeague.descHint')),
        maxLength: 500,
        maxLines: 2,
      );

  Widget _buildFormatSelector(String lang) {
    final options = [
      (
        'round_robin',
        tr(lang, 'createLeague.league'),
        'Todos contra todos'
      ), // no key for subtitle
      (
        'knockout',
        tr(lang, 'createLeague.cup'),
        'Partidos de copa'
      ), // no key for subtitle
      (
        'swiss',
        tr(lang, 'createLeague.swiss'),
        'Rondas emparejadas'
      ), // no key for subtitle
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(lang, 'createLeague.formatLabel'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: options
              .map((opt) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FormatOption(
                        value: opt.$1,
                        label: opt.$2,
                        subtitle: opt.$3,
                        selected: _format == opt.$1,
                        onTap: () => setState(() => _format = opt.$1),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMaxTeamsSlider(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(tr(lang, 'createLeague.maxTeams'),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(
            '$_maxTeams',
            style: TextStyle(
                fontFamily: AppTextStyles.displayFont,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
        ]),
        Slider(
          value: _maxTeams.toDouble(),
          min: 2,
          max: 20,
          divisions: 18,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.surfaceLight,
          onChanged: (v) => setState(() => _maxTeams = v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('2',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            Text('20',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetChips(String lang) {
    final budgets = [
      (800000, '800k'),
      (1000000, '1000k'),
      (1050000, '1050k'),
      (1100000, '1100k'),
      (1200000, '1200k'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(lang, 'createLeague.budget'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: budgets
              .map((b) => ChoiceChip(
                    label: Text(b.$2),
                    selected: _startingBudget == b.$1,
                    onSelected: (_) => setState(() => _startingBudget = b.$1),
                    selectedColor: AppColors.primary.withOpacity(0.8),
                    backgroundColor: AppColors.card,
                    labelStyle: TextStyle(
                      color: _startingBudget == b.$1
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    side: BorderSide(
                      color: _startingBudget == b.$1
                          ? AppColors.primary
                          : AppColors.surfaceLight,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRuleToggle(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(String lang) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isLoading ? null : _submit,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
        label: Text(
            _isLoading
                ? 'Creando...'
                : tr(lang, 'createLeague.create'), // 'Creando...' has no key
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(0, 52),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {bool required = false}) =>
      InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.surfaceLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        counterStyle: TextStyle(color: AppColors.textMuted),
      );
}

// ── Format Option Widget ──

class _FormatOption extends StatelessWidget {
  final String value;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary.withOpacity(0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color:
                    selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textMuted, fontSize: 9.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
