import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_nav_bar.dart';

// --- State Enum ---------------------------------------------------------------

enum JoinedGroupState { active, defaulting, payout }

// --- Entry Point --------------------------------------------------------------

class JoinedGroupDetailScreen extends StatelessWidget {
  const JoinedGroupDetailScreen({
    super.key,
    this.state = JoinedGroupState.active,
    this.groupName,
  });

  final JoinedGroupState state;
  final String? groupName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: const AjoNavBar(active: AjoTab.pools),
      body: CustomScrollView(
        slivers: [
          // -- Shared App Bar ---------------------------------------------
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
            title: Text(
              'Group Details',
              style: AppTypography.titleMd(cs.primary),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.more_vert_rounded,
                    color: cs.onSurface, size: 22),
                onPressed: () {},
              ),
            ],
          ),

          // -- State-specific body ----------------------------------------
          SliverToBoxAdapter(
            child: switch (state) {
              JoinedGroupState.active => _ActiveBody(groupName: groupName),
              JoinedGroupState.defaulting => const _DefaultingBody(),
              JoinedGroupState.payout => const _PayoutBody(),
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STATE 1 — ACTIVE
// ══════════════════════════════════════════════════════════════════════════════

class _ActiveBody extends StatelessWidget {
  const _ActiveBody({this.groupName});

  final String? groupName;

  static const _members = [
    _MemberData(
      name: 'Adebayo Collins',
      slot: 5,
      role: 'Organizer',
      isYou: true,
      isPaid: true,
      paidAt: 'Nov 28, 09:12 AM',
    ),
    _MemberData(
      name: 'Chinelo Okafor',
      slot: 8,
      role: 'Contributor',
      isYou: false,
      isPaid: false,
      paidAt: null,
    ),
    _MemberData(
      name: 'Tunde Eniola',
      slot: 2,
      role: 'Contributor',
      isYou: false,
      isPaid: true,
      paidAt: 'Dec 01, 02:45 PM',
    ),
    _MemberData(
      name: 'Sarah Jenkins',
      slot: 11,
      role: 'Contributor',
      isYou: false,
      isPaid: false,
      paidAt: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Header: label + title + avatar stack ----------------------
          Text('ACTIVE SAVINGS GROUP',
              style: AppTypography.labelSm(cs.primary)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  groupName ?? 'Wealth Builders\nAjo',
                  style: AppTypography.headlineSm(cs.onSurface)
                      .copyWith(fontWeight: FontWeight.w800, height: 1.15),
                ),
              ),
              _MemberAvatarStack(count: 9),
            ],
          ),
          const SizedBox(height: 20),

          // -- Cycle Progress Card ----------------------------------------
          _ActiveCycleCard(),
          const SizedBox(height: 16),

          // -- Contribution + Next Payout ---------------------------------
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Contribution',
                  value: '₦50,000',
                  valueColor: cs.primary,
                  sub: 'PER MEMBER',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Next Payout',
                  value: 'Dec 15',
                  valueColor: cs.onSurface,
                  sub: '12 DAYS LEFT',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // -- CTA card ---------------------------------------------------
          _MakeContributionCta(),
          const SizedBox(height: 28),

          // -- Member Status ----------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Member Status',
                  style: AppTypography.titleMd(cs.onSurface)),
              Text('CYCLE 5 TRACK',
                  style: AppTypography.labelSm(cs.primary)),
            ],
          ),
          const SizedBox(height: 14),
          ..._members.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActiveMemberRow(data: m),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                'View All 12 Members',
                style: AppTypography.labelMd(cs.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // -- Pot Summary ------------------------------------------------
          _PotSummaryCard(),
        ],
      ),
    );
  }
}

// --- Active: Cycle Progress Card ----------------------------------------------

class _ActiveCycleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    const progress = 0.42;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        border: Border(left: BorderSide(color: cs.primary, width: 4)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Cycle Progress',
                  style: AppTypography.bodySm(cs.onSurfaceVariant)),
              const Spacer(),
              Icon(Icons.sync_rounded, color: cs.primary, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text('Cycle 5 of 12',
              style: AppTypography.titleLg(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 8,
              child: Stack(children: [
                Container(color: cs.surfaceContainerHigh),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '42% of the journey completed',
            style: AppTypography.bodySm(cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// --- Active: Make Contribution CTA --------------------------------------------

class _MakeContributionCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready for Cycle 5?',
            style: AppTypography.titleLg(cs.onPrimary)
                .copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Ensure your contribution is made by midnight on the 14th.',
            style: AppTypography.bodySm(cs.onPrimary.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: cs.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: cs.onPrimary.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Make Contribution',
                    style: AppTypography.labelLg(cs.onPrimary),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.account_balance_wallet_outlined,
                      color: cs.onPrimary, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Active: Member Row --------------------------------------------------------

class _MemberData {
  const _MemberData({
    required this.name,
    required this.slot,
    required this.role,
    required this.isYou,
    required this.isPaid,
    required this.paidAt,
  });

  final String name;
  final int slot;
  final String role;
  final bool isYou;
  final bool isPaid;
  final String? paidAt;
}

class _ActiveMemberRow extends StatelessWidget {
  const _ActiveMemberRow({required this.data});
  final _MemberData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        border: data.isYou
            ? Border(left: BorderSide(color: cs.primary, width: 3))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surfaceContainerHigh,
            ),
            child: Icon(Icons.person_rounded,
                color: cs.onSurfaceVariant, size: 22),
          ),
          const SizedBox(width: 12),

          // Name + slot
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(data.name,
                        style: AppTypography.titleSm(cs.onSurface)),
                    if (data.isYou) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text('YOU',
                            style: AppTypography.labelSm(cs.onPrimary)
                                .copyWith(fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Slot #${data.slot} • ${data.role}',
                  style: AppTypography.bodySm(cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (data.isPaid)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: cs.primary, size: 16),
                    const SizedBox(width: 4),
                    Text('PAID',
                        style: AppTypography.labelSm(cs.primary)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded,
                        color: cs.onSurfaceVariant, size: 16),
                    const SizedBox(width: 4),
                    Text('PENDING',
                        style: AppTypography.labelSm(cs.onSurfaceVariant)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              if (data.paidAt != null) ...[
                const SizedBox(height: 3),
                Text(data.paidAt!,
                    style: AppTypography.bodySm(cs.onSurfaceVariant)
                        .copyWith(fontSize: 10)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// --- Active: Pot Summary Card --------------------------------------------------

class _PotSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.account_balance_outlined,
                color: cs.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Total Pot Collected ',
                        style: AppTypography.bodyMd(cs.onSurface)),
                    Text('₦150,000',
                        style: AppTypography.titleSm(cs.primary)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Remaining to collect   ₦450,000',
                  style: AppTypography.bodySm(cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  'BANK PROTECTION ACTIVE',
                  style: AppTypography.labelSm(cs.onSurfaceVariant)
                      .copyWith(fontSize: 10, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STATE 2 — DEFAULTING
// ══════════════════════════════════════════════════════════════════════════════

class _DefaultingBody extends StatelessWidget {
  const _DefaultingBody();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Urgent Banner ----------------------------------------------
          _UrgentBanner(),
          const SizedBox(height: 20),

          // -- Group Info Card --------------------------------------------
          _DefaultingGroupCard(),
          const SizedBox(height: 20),

          // -- Trust Score Impact -----------------------------------------
          _TrustScoreCard(),
          const SizedBox(height: 20),

          // -- Next Payout ------------------------------------------------
          _NextPayoutCard(),
          const SizedBox(height: 28),

          // -- Group Members ----------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Group Members',
                  style: AppTypography.titleMd(cs.onSurface)),
              TextButton(
                onPressed: () {},
                child: Text('View History',
                    style: AppTypography.labelMd(cs.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DefaultingMembersList(),
        ],
      ),
    );
  }
}

// --- Defaulting: Urgent Banner ------------------------------------------------

class _UrgentBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFD63B2B);

    return Container(
      decoration: BoxDecoration(
        color: red,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.warning_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'URGENT: PAYMENT OVERDUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13),
                    children: [
                      TextSpan(
                          text:
                              'You missed the contribution scheduled for Dec 1st. '
                              'Your status is currently marked as '),
                      TextSpan(
                        text: 'DEFAULTING',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Defaulting: Group Card ---------------------------------------------------

class _DefaultingGroupCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    const red = Color(0xFFD63B2B);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
              border:
                  Border.all(color: red.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'STATUS: DEFAULTING',
              style: TextStyle(
                color: red,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Wealth Builders Ajo',
              style: AppTypography.headlineSm(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Cycle 4 of 12  •  Monthly Contribution',
                  style: AppTypography.bodySm(cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('INDIVIDUAL CONTRIBUTION',
                    style: AppTypography.labelSm(cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('₦50,000.00',
                    style: AppTypography.displaySm(cs.primary)
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Missed Payment Box
          Container(
            decoration: BoxDecoration(
              color: red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: red.withValues(alpha: 0.25)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Missed: Dec 1, 2023',
                              style: AppTypography.titleSm(red)),
                          const SizedBox(height: 3),
                          Text(
                              'Penalty: +₦205.00 late fee\napplied',
                              style: AppTypography.bodySm(
                                  cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total Overdue',
                            style: AppTypography.labelSm(
                                cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('₦50,000.00',
                            style: AppTypography.titleLg(cs.onSurface)
                                .copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'MAKE CONTRIBUTION NOW',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.bolt_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Defaulting: Trust Score Card ---------------------------------------------

class _TrustScoreCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    const red = Color(0xFFD63B2B);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trust Score Impact',
              style: AppTypography.titleMd(cs.onSurface)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: AppTypography.bodySm(cs.onSurfaceVariant),
              children: const [
                TextSpan(
                    text:
                        'Continuous defaulting will decrease your visibility '
                        'for high-yield pools and peer lending opportunities. '),
                TextSpan(
                  text: 'Current Score Drop: -45 pts.',
                  style: TextStyle(
                    color: red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar: poor → fair → excellent
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 8,
              child: Stack(children: [
                Container(color: cs.surfaceContainerHigh),
                FractionallySizedBox(
                  widthFactor: 0.38,
                  child: Container(color: red),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('POOR',
                  style: AppTypography.labelSm(cs.onSurfaceVariant)
                      .copyWith(fontSize: 10)),
              Text('CURRENT: FAIR',
                  style: AppTypography.labelSm(cs.onSurfaceVariant)
                      .copyWith(fontSize: 10)),
              Text('EXCELLENT',
                  style: AppTypography.labelSm(cs.onSurfaceVariant)
                      .copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Defaulting: Next Payout Card ---------------------------------------------

class _NextPayoutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        border: Border(left: BorderSide(color: cs.primary, width: 4)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEXT PAYOUT',
              style: AppTypography.labelSm(cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text('Jan 15, 2024',
              style: AppTypography.headlineSm(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceContainerHigh,
                ),
                child: Icon(Icons.person_rounded,
                    color: cs.onSurfaceVariant, size: 16),
              ),
              const SizedBox(width: 8),
              Text('Recipient: Adekunle O.',
                  style: AppTypography.bodySm(cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Defaulting: Members List --------------------------------------------------

class _DefaultingMembersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    const red = Color(0xFFD63B2B);

    final members = [
      _DefaultMember(
          name: 'You (The Builder)',
          sub: 'Payment Pending  •  Missed Dec 1st',
          isYou: true,
          hasPaid: false),
      _DefaultMember(
          name: 'Sarah Mitchell',
          sub: 'Paid Nov 28th',
          isYou: false,
          hasPaid: true),
      _DefaultMember(
          name: 'Marcus Chen',
          sub: 'Paid Nov 30th',
          isYou: false,
          hasPaid: true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        border: Border(left: BorderSide(color: red, width: 4)),
      ),
      child: Column(
        children: members.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.surfaceContainerHigh,
                          ),
                          child: Icon(Icons.person_rounded,
                              color: cs.onSurfaceVariant, size: 22),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: m.hasPaid
                                  ? cs.primary
                                  : red,
                              border: Border.all(
                                  color: cs.surfaceContainerLowest,
                                  width: 1.5),
                            ),
                            child: Icon(
                              m.hasPaid
                                  ? Icons.check_rounded
                                  : Icons.close_rounded,
                              color: Colors.white,
                              size: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name,
                              style: AppTypography.titleSm(cs.onSurface)),
                          const SizedBox(height: 3),
                          Text(
                            m.sub,
                            style: AppTypography.bodySm(
                              m.isYou ? red : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (m.isYou)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: red.withValues(alpha: 0.4)),
                        ),
                        child: Text('PAY',
                            style: AppTypography.labelMd(red)
                                .copyWith(fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
              ),
              if (i < members.length - 1)
                Divider(
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: cs.outlineVariant.withValues(alpha: 0.2)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DefaultMember {
  const _DefaultMember({
    required this.name,
    required this.sub,
    required this.isYou,
    required this.hasPaid,
  });
  final String name;
  final String sub;
  final bool isYou;
  final bool hasPaid;
}

// ══════════════════════════════════════════════════════════════════════════════
// STATE 3 — PAYOUT
// ══════════════════════════════════════════════════════════════════════════════

class _PayoutBody extends StatelessWidget {
  const _PayoutBody();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -- "It's Your Turn!" hero card ----------------------------------
        _ItsYourTurnHero(),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // -- Payout Amount Card ---------------------------------------
              _PayoutAmountCard(),
              const SizedBox(height: 24),

              // -- Group name + Cycle Progress ------------------------------
              Text('Wealth Builders Ajo',
                  style: AppTypography.titleLg(cs.onSurface)
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _PayoutCycleCard(),
              const SizedBox(height: 12),

              // -- Members + Frequency --------------------------------------
              Row(
                children: [
                  Expanded(
                    child: _PayoutStatCard(
                      icon: Icons.people_outline_rounded,
                      label: 'Members',
                      value: '12 People',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PayoutStatCard(
                      icon: Icons.calendar_month_outlined,
                      label: 'Frequency',
                      value: 'Monthly',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // -- Contribution History -------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Contribution History',
                      style: AppTypography.titleMd(cs.onSurface)),
                  TextButton(
                    onPressed: () {},
                    child: Text('View All',
                        style: AppTypography.labelMd(cs.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ContributionHistoryList(),
              const SizedBox(height: 28),

              // -- Withdraw Payout CTA --------------------------------------
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 20, color: cs.onPrimary),
                      const SizedBox(width: 10),
                      Text('Withdraw Payout',
                          style: AppTypography.labelLg(cs.onPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Payout: Hero Card ---------------------------------------------------------

class _ItsYourTurnHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.primary,
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.celebration_rounded,
                color: cs.onPrimary, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            "It's Your Turn!",
            style: AppTypography.headlineSm(cs.onPrimary)
                .copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Congratulations! You are the designated recipient '
            'for this rotation of Wealth Builders Ajo.',
            style:
                AppTypography.bodySm(cs.onPrimary.withValues(alpha: 0.85)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// --- Payout: Amount Card -------------------------------------------------------

class _PayoutAmountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        border: Border(left: BorderSide(color: cs.primary, width: 4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL PAYOUT AMOUNT',
              style: AppTypography.labelSm(cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '₦600,000',
                  style: AppTypography.displayMd(cs.onSurface)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: ' .00',
                  style: AppTypography.titleLg(cs.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PayoutMetaTile(
                  label: 'PAYOUT DATE',
                  value: 'Dec 15, 2023',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PayoutMetaTile(
                  label: 'GROUP STATUS',
                  value: 'Active Payout',
                  isActive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutMetaTile extends StatelessWidget {
  const _PayoutMetaTile({
    required this.label,
    required this.value,
    this.isActive = false,
  });

  final String label;
  final String value;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.labelSm(cs.onSurfaceVariant)
                  .copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          if (isActive)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(value, style: AppTypography.titleSm(cs.onSurface)),
              ],
            )
          else
            Text(value, style: AppTypography.titleSm(cs.onSurface)),
        ],
      ),
    );
  }
}

// --- Payout: Cycle Progress Card ----------------------------------------------

class _PayoutCycleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    const progress = 0.83;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cycle Progress',
                      style: AppTypography.bodySm(cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('10 of 12 Contributions',
                      style: AppTypography.titleMd(cs.onSurface)
                          .copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              Text('83%',
                  style: AppTypography.titleMd(cs.primary)
                      .copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 8,
              child: Stack(children: [
                Container(color: cs.surfaceContainerHigh),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Payout: Stat Card ---------------------------------------------------------

class _PayoutStatCard extends StatelessWidget {
  const _PayoutStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 24),
          const SizedBox(height: 10),
          Text(label,
              style: AppTypography.bodySm(cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.titleMd(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// --- Payout: Contribution History ---------------------------------------------

class _ContributionHistoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    final history = [
      _ContributionEntry(
        label: 'November Contribution',
        sub: 'Paid on Nov 02',
        amount: '₦50,000',
        isPaid: true,
      ),
      _ContributionEntry(
        label: 'December Contribution',
        sub: 'Due Dec 01',
        amount: '₦50,000',
        isPaid: false,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: Column(
        children: history.asMap().entries.map((entry) {
          final i = entry.key;
          final h = entry.value;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: h.isPaid
                            ? cs.primary.withValues(alpha: 0.15)
                            : cs.surfaceContainerHigh,
                      ),
                      child: Icon(
                        h.isPaid
                            ? Icons.check_rounded
                            : Icons.schedule_rounded,
                        color: h.isPaid
                            ? cs.primary
                            : cs.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.label,
                              style: AppTypography.titleSm(
                                h.isPaid
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                              )),
                          const SizedBox(height: 2),
                          Text(h.sub,
                              style:
                                  AppTypography.bodySm(cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Text(h.amount,
                        style: AppTypography.titleSm(
                          h.isPaid ? cs.onSurface : cs.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              if (i < history.length - 1)
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: cs.outlineVariant.withValues(alpha: 0.2)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ContributionEntry {
  const _ContributionEntry({
    required this.label,
    required this.sub,
    required this.amount,
    required this.isPaid,
  });
  final String label;
  final String sub;
  final String amount;
  final bool isPaid;
}

// --- Shared: Member Avatar Stack ----------------------------------------------

class _MemberAvatarStack extends StatelessWidget {
  const _MemberAvatarStack({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const overlap = 18.0;
    const avatarSize = 36.0;
    const visibleCount = 3;

    return SizedBox(
      height: avatarSize,
      width: visibleCount * (avatarSize - overlap) + overlap + 40,
      child: Stack(
        children: [
          ...List.generate(visibleCount, (i) {
            return Positioned(
              left: i * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceContainerHigh,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                child: Icon(Icons.person_rounded,
                    color: cs.onSurfaceVariant, size: 18),
              ),
            );
          }),
          Positioned(
            left: visibleCount * (avatarSize - overlap),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary,
                border: Border.all(color: cs.surface, width: 2),
              ),
              child: Center(
                child: Text(
                  '+$count',
                  style: AppTypography.labelSm(cs.onPrimary)
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Shared: Stat Tile --------------------------------------------------------

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.sub,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String sub;

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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySm(cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.titleLg(valueColor)
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub,
              style: AppTypography.labelSm(cs.onSurfaceVariant)
                  .copyWith(fontSize: 10, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}