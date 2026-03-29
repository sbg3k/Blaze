import 'package:flutter/material.dart';

import '../../../core/api/api_repositories.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../../core/widgets/ajo_nav_bar.dart';
import '../widgets/pool_form_widgets.dart';

class ReviewGroupScreen extends StatefulWidget {
  const ReviewGroupScreen({
    super.key,
    required this.groupName,
    required this.monthlyCon,
    required this.type,
    required this.interval,
    this.trustScore = 750,
    this.minIncome = 0,
    this.description = '',
  });

  final String groupName;
  final int monthlyCon;
  final String type;
  final String interval;
  final int trustScore;
  final int minIncome;
  final String description;

  @override
  State<ReviewGroupScreen> createState() => _ReviewGroupScreenState();
}

class _ReviewGroupScreenState extends State<ReviewGroupScreen> {
  bool _submitting = false;

  Future<void> _createGroup() async {
    setState(() => _submitting = true);
    try {
      await groupsHttpApi.createGroup(
        name: widget.groupName,
        description: widget.description,
        type: widget.type,
        monthlyCon: widget.monthlyCon,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully.')),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                      'Review Group',
                      style: AppTypography.titleLg(cs.onSurface),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── GROUP DETAILS ────────────────────────────────
                    const PoolSectionLabel('GROUP DETAILS'),
                    const SizedBox(height: 10),

                    // Group name card
                    ReviewCard(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.group_rounded,
                                  color: cs.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GROUP NAME',
                                  style: AppTypography.labelSm(
                                          cs.onSurfaceVariant)
                                      .copyWith(
                                          fontSize: 9, letterSpacing: 0.8),
                                ),
                                Text(
                                  widget.groupName,
                                  style: AppTypography.titleMd(cs.onSurface)
                                      .copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Amount + interval row
                    Row(
                      children: [
                        Expanded(
                          child: ReviewCard(
                            children: [
                              Text(
                                'INDIVIDUAL AMOUNT',
                                style: AppTypography.labelSm(
                                        cs.onSurfaceVariant)
                                    .copyWith(
                                        fontSize: 9, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₦${widget.monthlyCon}',
                                style: AppTypography.titleMd(cs.primary)
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ReviewCard(
                            children: [
                              Text(
                                'INTERVAL',
                                style: AppTypography.labelSm(
                                        cs.onSurfaceVariant)
                                    .copyWith(
                                        fontSize: 9, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.interval,
                                style: AppTypography.titleMd(cs.onSurface)
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Visibility
                    ReviewCard(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.public_rounded,
                                color: cs.onSurfaceVariant, size: 20),
                            const SizedBox(width: 10),
                            Text('Visibility Status',
                                style: AppTypography.bodyMd(cs.onSurface)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                widget.type.toUpperCase(),
                                style: AppTypography.labelSm(cs.onPrimary)
                                    .copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── REQUIREMENTS ────────────────────────────────
                    const PoolSectionLabel('REQUIREMENTS'),
                    const SizedBox(height: 10),

                    ReviewCard(
                      children: [
                        _ReviewDataRow(
                          label: 'MIN. TRUST SCORE',
                          value: '${widget.trustScore}+',
                          icon: Icons.verified_user_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ReviewCard(
                      children: [
                        _ReviewDataRow(
                          label: 'MIN. MONTHLY INCOME',
                          value: '₦${widget.minIncome}',
                          icon: Icons.payments_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── ABOUT ────────────────────────────────────────
                    const PoolSectionLabel('ABOUT THE GROUP'),
                    const SizedBox(height: 10),

                    ReviewCard(
                      children: [
                        Text(
                          'DESCRIPTION & PURPOSE',
                          style: AppTypography.labelSm(cs.onSurfaceVariant)
                              .copyWith(fontSize: 9, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.description.isEmpty
                              ? 'This group is designed for professionals '
                                  'looking to build a robust emergency fund '
                                  'through disciplined weekly contributions. '
                                  'The goal is to reach a total pool of '
                                  '₦1,000,000 per cycle.'
                              : widget.description,
                          style: AppTypography.bodyMd(cs.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── CTA ─────────────────────────────────────────
                    AjoGradientButton(
                      label: 'Create Group',
                      suffixIcon: Icons.rocket_launch_rounded,
                      isLoading: _submitting,
                      onPressed: _submitting ? null : _createGroup,
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

// ─── Review data row ──────────────────────────────────────────────────────────

class _ReviewDataRow extends StatelessWidget {
  const _ReviewDataRow({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSm(cs.onSurfaceVariant)
                  .copyWith(fontSize: 9, letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.titleMd(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const Spacer(),
        Icon(icon, color: cs.primary, size: 24),
      ],
    );
  }
}
