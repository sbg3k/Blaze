import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../../core/widgets/ajo_nav_bar.dart';
import '../widgets/pool_form_widgets.dart';
import 'review_group_screen.dart';

class GroupRequirementsScreen extends StatefulWidget {
  const GroupRequirementsScreen({
    super.key,
    required this.groupName,
    required this.monthlyCon,
    required this.type,
    required this.interval,
  });

  final String groupName;
  final int monthlyCon;
  final String type;
  final String interval;

  @override
  State<GroupRequirementsScreen> createState() =>
      _GroupRequirementsScreenState();
}

class _GroupRequirementsScreenState extends State<GroupRequirementsScreen> {
  double _trustScore = 750;
  final _incomeCtrl = TextEditingController(text: '0.00');
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _descCtrl.dispose();
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
                    icon:
                        Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Group Requirements',
                      style: AppTypography.titleLg(cs.onSurface),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'STEP 2 OF 3',
                      style: AppTypography.labelSm(cs.onPrimary).copyWith(
                          fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),

            // ── Step dots ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == 1;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? cs.primary
                          : cs.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  );
                }),
              ),
            ),

            // ── Form ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Requirements',
                        style: AppTypography.headlineSm(cs.onSurface)),
                    const SizedBox(height: 16),

                    _TrustScoreCard(
                      value: _trustScore,
                      onChanged: (v) => setState(() => _trustScore = v),
                    ),
                    const SizedBox(height: 20),

                    const PoolFieldLabel('Minimum Monthly Income'),
                    const SizedBox(height: 8),
                    _MoneyField(controller: _incomeCtrl, prefix: '\$'),
                    const SizedBox(height: 6),
                    Text(
                      'Members must verify this income to join the pool.',
                      style: AppTypography.labelSm(cs.onSurfaceVariant)
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 24),

                    Text('Additional Info',
                        style: AppTypography.headlineSm(cs.onSurface)),
                    const SizedBox(height: 16),

                    const PoolFieldLabel('Group Description & Purpose'),
                    const SizedBox(height: 8),
                    _TextAreaField(
                      controller: _descCtrl,
                      hint: 'What is the goal of this Ajo group? E.g. Saving '
                          'for home downpayments, business capital, etc.',
                    ),
                    const SizedBox(height: 16),

                    const PoolInfoBanner(
                      text: 'A clear description helps potential members '
                          'understand the commitment and culture of your group.',
                    ),
                    const SizedBox(height: 28),

                    AjoGradientButton(
                      label: 'Continue to Summary',
                      suffixIcon: Icons.chevron_right_rounded,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReviewGroupScreen(
                            groupName: widget.groupName,
                            monthlyCon: widget.monthlyCon,
                            type: widget.type,
                            interval: widget.interval,
                            trustScore: _trustScore.toInt(),
                            minIncome: int.tryParse(
                                  _incomeCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                                ) ??
                                0,
                            description: _descCtrl.text,
                          ),
                        ),
                      ),
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

// ─── Trust score card ─────────────────────────────────────────────────────────

class _TrustScoreCard extends StatelessWidget {
  const _TrustScoreCard({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Minimum Trust Score',
                  style: AppTypography.titleSm(cs.onSurface)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  value.toInt().toString(),
                  style: AppTypography.labelMd(cs.onPrimary)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: cs.primary,
              inactiveTrackColor: cs.surfaceContainerHighest,
              thumbColor: cs.primary,
              overlayColor: cs.primary.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1000,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['0', '500', '1000']
                  .map((e) => Text(e,
                      style: AppTypography.labelSm(cs.onSurfaceVariant)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Money prefix field ───────────────────────────────────────────────────────

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.controller, required this.prefix});
  final TextEditingController controller;
  final String prefix;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(prefix,
                style: AppTypography.titleMd(cs.onSurfaceVariant)),
          ),
          Container(
              width: 1,
              height: 24,
              color: cs.primary.withValues(alpha: 0.20)),
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

// ─── Textarea ─────────────────────────────────────────────────────────────────

class _TextAreaField extends StatelessWidget {
  const _TextAreaField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
      ),
      child: TextField(
        controller: controller,
        maxLines: 5,
        style: AppTypography.bodyMd(cs.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMd(cs.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}
