import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../../core/widgets/ajo_nav_bar.dart';
import '../widgets/pool_form_widgets.dart';
import 'group_requirements_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0.00');
  String _interval = 'Weekly';
  bool _isPublic = true;
  bool _submitting = false;

  static const _intervals = ['Daily', 'Weekly', 'Bi-weekly', 'Monthly'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: const AjoNavBar(active: AjoTab.pools),
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Create New Group',
                      style: AppTypography.titleLg(cs.onSurface),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Form ────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PoolFieldLabel('Group Name'),
                    const SizedBox(height: 8),
                    PoolTextField(controller: _nameCtrl, hint: 'Enter group name'),
                    const SizedBox(height: 20),

                    const PoolFieldLabel('Individual Amount'),
                    const SizedBox(height: 8),
                    _AmountField(controller: _amountCtrl),
                    const SizedBox(height: 20),

                    const PoolFieldLabel('Contribution Interval'),
                    const SizedBox(height: 8),
                    _DropdownField(
                      value: _interval,
                      items: _intervals,
                      onChanged: (v) => setState(() => _interval = v!),
                    ),
                    const SizedBox(height: 20),

                    _ToggleCard(
                      title: 'Public Group',
                      subtitle: 'Anyone can search and join this group',
                      value: _isPublic,
                      onChanged: (v) => setState(() => _isPublic = v),
                    ),
                    const SizedBox(height: 16),

                    const PoolInfoBanner(
                      text: 'You will be the group administrator. You can '
                          'invite members after creating the group.',
                    ),
                    const SizedBox(height: 28),

                    AjoGradientButton(
                      label: 'Next',
                      suffixIcon: Icons.chevron_right_rounded,
                      isLoading: _submitting,
                      onPressed: _submitting
                          ? null
                          : () {
                              final amount = int.tryParse(
                                    _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                                  ) ??
                                  0;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GroupRequirementsScreen(
                                    groupName: _nameCtrl.text.trim(),
                                    monthlyCon: amount,
                                    type: _isPublic ? 'public' : 'private',
                                    interval: _interval,
                                  ),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Amount field with ₦ prefix ───────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(11)),
            ),
            child: Center(
              child: Text(
                '₦',
                style: AppTypography.titleMd(cs.primary)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.titleMd(cs.onSurface),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14),
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dropdown field ───────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: cs.onSurfaceVariant),
          dropdownColor: cs.surfaceContainerHigh,
          style: AppTypography.bodyMd(cs.onSurface),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Toggle card ──────────────────────────────────────────────────────────────

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSm(cs.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.bodySm(cs.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: cs.onPrimary,
            activeTrackColor: cs.primary,
          ),
        ],
      ),
    );
  }
}
