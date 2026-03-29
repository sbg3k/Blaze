import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../../core/widgets/ajo_nav_bar.dart';
import '../../../core/api/api_repositories.dart';
import '../../../core/network/api_client.dart';
import '../models/group_model.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.group});
  final GroupData group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: const AjoNavBar(active: AjoTab.pools),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // -- Header ------------------------------------------------
              SliverAppBar(
                pinned: true,
                backgroundColor: cs.surface,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: cs.onSurface, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.share_outlined,
                        color: cs.onSurface, size: 22),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded,
                        color: cs.onSurface, size: 22),
                    onPressed: () {},
                  ),
                ],
                title: Text(
                  'Group Details',
                  style: AppTypography.titleMd(cs.primary),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -- Group avatar + verified badge ----------------
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: cs.primary, width: 2),
                              ),
                              child: Icon(group.icon,
                                  color: cs.primary, size: 44),
                            ),
                            Positioned(
                              bottom: -10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    'VERIFIED',
                                    style: AppTypography.labelSm(cs.onPrimary)
                                        .copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // -- Name + admin ---------------------------------
                      Center(
                        child: Column(
                          children: [
                            Text(group.name,
                                style: AppTypography.headlineSm(cs.onSurface)
                                    .copyWith(fontWeight: FontWeight.w800),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified_outlined,
                                    size: 14, color: cs.primary),
                                const SizedBox(width: 4),
                                Text('Admin James',
                                    style: AppTypography.bodySm(cs.primary)),
                                Text(' • Active since Jan 2024',
                                    style: AppTypography.bodySm(
                                        cs.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // -- Stats row ------------------------------------
                      Row(
                        children: [
                          _StatCard(
                            label: 'MEMBERS',
                            value: '${group.members}/12',
                            sub: null,
                            progress: group.capacityFraction,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'REMAINING',
                            value:
                                '${(12 - group.members).clamp(0, 12)} Slots',
                            sub: group.capacityFraction > 0.8
                                ? 'Closing Soon'
                                : 'Available',
                            progress: null,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'PER PERSON',
                            value: '₦50k',
                            sub: 'Fixed amount',
                            progress: null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // -- Contribution schedule ------------------------
                      _SectionTitle(
                          icon: Icons.calendar_month_outlined,
                          title: 'Contribution Schedule'),
                      const SizedBox(height: 12),
                      _InfoCard(
                        children: [
                          _InfoRow(label: 'Frequency', value: 'Weekly',
                              valueWidget: _Chip('Weekly')),
                          _Divider(),
                          _InfoRow(
                              label: 'Total Payout',
                              value: '₦600,000',
                              valueColor: cs.primary),
                          _Divider(),
                          _InfoRow(
                              label: 'Next Payout Date',
                              value: 'Dec 15, 2024'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // -- Requirements ---------------------------------
                      _SectionTitle(
                          icon: Icons.checklist_rounded,
                          title: 'Requirements'),
                      const SizedBox(height: 12),
                      _RequirementRow(
                        icon: Icons.security_rounded,
                        title: 'Min. Trust Score: 750+',
                        sub: 'Based on past contributions',
                        met: true,
                      ),
                      const SizedBox(height: 10),
                      _RequirementRow(
                        icon: Icons.work_outline_rounded,
                        title: 'Employment Record',
                        sub: 'Proof of income required',
                        met: true,
                      ),
                      const SizedBox(height: 24),

                      // -- About -----------------------------------------
                      _SectionTitle(
                          icon: Icons.info_outline_rounded,
                          title: 'About this Group'),
                      const SizedBox(height: 12),
                      Text(
                        'This group is designed for ambitious professionals '
                        'looking to save towards long-term investments or major '
                        'purchases. Administered by James, a top-rated coordinator '
                        'with 3+ years of successful Ajo cycles. Our goal is '
                        '100% on-time payouts.',
                        style: AppTypography.bodyMd(cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // -- Sticky CTA ------------------------------------------------
          Positioned(
            bottom: 56 + MediaQuery.of(context).padding.bottom,
            left: 20,
            right: 20,
            child: AjoGradientButton(
              label: 'REQUEST TO JOIN GROUP',
              onPressed: () async {
                final id = group.id;
                if (id == null || id.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group id missing.')),
                  );
                  return;
                }
                try {
                  await groupsHttpApi.requestJoinGroup(groupId: id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Join request sent.')),
                  );
                } on ApiException catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Stat card ----------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.progress,
  });
  final String label;
  final String value;
  final String? sub;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTypography.labelSm(cs.onSurfaceVariant)
                    .copyWith(fontSize: 9, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value,
                style: AppTypography.titleMd(cs.onSurface)
                    .copyWith(fontWeight: FontWeight.w800)),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub!,
                  style: AppTypography.labelSm(cs.onSurfaceVariant)
                      .copyWith(fontSize: 10)),
            ],
            if (progress != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: SizedBox(
                  height: 4,
                  child: Stack(children: [
                    Container(color: cs.surfaceContainerHighest),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(color: cs.primary),
                    ),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Info card ----------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWidget,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Text(label, style: AppTypography.bodyMd(cs.onSurfaceVariant)),
          const Spacer(),
          valueWidget ??
              Text(
                value,
                style: AppTypography.titleSm(valueColor ?? cs.onSurface),
              ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(
        height: 1,
        color: cs.outlineVariant.withValues(alpha: 0.15));
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label,
          style: AppTypography.labelSm(cs.onPrimary)
              .copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

// --- Requirement row ----------------------------------------------------------

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.met,
  });
  final IconData icon;
  final String title;
  final String sub;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSm(cs.onSurface)),
                Text(sub,
                    style: AppTypography.labelSm(cs.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(
            met ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: met ? cs.primary : cs.error,
            size: 22,
          ),
        ],
      ),
    );
  }
}

// --- Section title ------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.onSurface, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTypography.titleMd(cs.onSurface)),
      ],
    );
  }
}
