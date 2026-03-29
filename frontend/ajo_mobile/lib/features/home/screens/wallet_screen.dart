import 'dart:ui';

import 'package:ajo_mobile/features/profile/screens/notifications_screen.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_repositories.dart';
import '../../../core/theme/theme.dart';
import '../models/user_profile.dart';
import 'deposit_screen.dart';
import 'referral_screen.dart';
import 'transactions_screen.dart';
import 'transfer_screen.dart';
import 'withdraw_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  UserProfile? _profile;
  WalletInfo? _liveWallet;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final profile = await profileHttpApi.getMe();
      WalletInfo? live;
      if (profile.wallet != null) {
        try {
          live = await profileHttpApi.getWallet();
        } catch (_) {
          live = profile.wallet;
        }
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _liveWallet = live;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _provisionWallet() async {
    try {
      await profileHttpApi.provisionWallet();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: CustomScrollView(
        slivers: [
         SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your Wallet',
                        style: AppTypography.headlineSm(cs.onSurface),
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: cs.onSurface,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _BalanceCard(
                  profile: _profile,
                  liveWallet: _liveWallet,
                  loading: _loading,
                  error: _error,
                  onProvisionWallet: _provisionWallet,
                  onRefresh: _load,
                ),
                const SizedBox(height: 16),
                _StatsRow(),
                const SizedBox(height: 28),
                _RecentTransactions(),
                const SizedBox(height: 20),
                _ReferralBanner(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _WalletAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: cs.surface.withValues(alpha: 0.80),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 20,
              right: 20,
              bottom: 12,
            ),
            child: Row(
              children: [
                Icon(Icons.menu_rounded, color: cs.onSurface, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Your Wallet',
                  style: AppTypography.titleLg(cs.primary),
                ),
                const Spacer(),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.secondaryContainer,
                  ),
                  child: Icon(
                    Icons.person,
                    color: cs.onSecondaryContainer,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      toolbarHeight: 72,
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.profile,
    required this.liveWallet,
    required this.loading,
    required this.error,
    required this.onProvisionWallet,
    required this.onRefresh,
  });

  final UserProfile? profile;
  final WalletInfo? liveWallet;
  final bool loading;
  final String? error;
  final Future<void> Function() onProvisionWallet;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    final wallet = liveWallet ?? profile?.wallet;
    final hasWallet = wallet != null;
    final canDeposit = wallet != null && wallet.status == 'active';
    const cardBg1 = Color(0xFF0A1F14);
    const cardBg2 = Color(0xFF1A2E1E);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [cardBg1, cardBg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL BALANCE',
            style: AppTypography.labelSm(
              const Color(0xFF6FCF97),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            wallet != null ? wallet.formattedBalance : 'Wallet Not Provisioned',
            style: AppTypography.displayMd(Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            wallet != null
                ? '${wallet.bankName ?? 'Bank'} • ${wallet.accountNumber ?? '--'}'
                : (error ?? 'Complete KYC to provision wallet.'),
            style: AppTypography.bodySm(Colors.white70),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  icon: Icons.add_circle_outline_rounded,
                  label: canDeposit
                      ? 'Deposit'
                      : hasWallet
                          ? 'Wallet ${wallet.status}'
                          : 'Provision',
                  isPrimary: true,
                  onTap: canDeposit
                      ? () {
                          Navigator.of(context)
                              .push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DepositScreen(),
                            ),
                          )
                              .then((_) => onRefresh());
                        }
                      : hasWallet
                          ? null
                          : () => onProvisionWallet(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CardButton(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Withdraw',
                  isPrimary: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WithdrawScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TransferButton(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TransferScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isPrimary ? cs.primary : const Color(0xFF2A3A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? cs.onPrimary : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMd(
                  isPrimary ? cs.onPrimary : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferButton extends StatelessWidget {
  const _TransferButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              color: cs.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Transfer',
              style: AppTypography.labelMd(cs.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up_rounded,
            iconColor: cs.primary,
            label: 'MONTHLY GROWTH',
            value: '+12.4%',
            valueColor: cs.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_rounded,
            iconColor: cs.onSurfaceVariant,
            label: 'ACTIVE POOLS',
            value: '3 Funds',
            valueColor: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppTypography.labelSm(cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleMd(valueColor),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Transactions ──────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  final _transactions = const [
    _TransactionData(
      title: 'Weekly Contribution',
      date: 'Oct 12, 2023 • 10:45 AM',
      amount: '-₦5,000',
      isDebit: true,
    ),
    _TransactionData(
      title: 'Deposit from Bank',
      date: 'Oct 10, 2023 • 02:30 PM',
      amount: '+₦50,000',
      isDebit: false,
    ),
    _TransactionData(
      title: 'Payout - Housing Fund',
      date: 'Oct 08, 2023 • 09:12 AM',
      amount: '+₦120,000',
      isDebit: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: AppTypography.titleMd(cs.onSurface),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TransactionsScreen(),
                ),
              ),
              child: Text(
                'View All',
                style: AppTypography.labelMd(cs.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._transactions
            .map((tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TransactionItem(data: tx),
                )),
      ],
    );
  }
}

class _TransactionData {
  const _TransactionData({
    required this.title,
    required this.date,
    required this.amount,
    required this.isDebit,
  });
  final String title;
  final String date;
  final String amount;
  final bool isDebit;
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({required this.data});
  final _TransactionData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    final iconBg = data.isDebit
        ? const Color(0xFF3D1A1A)
        : cs.primary.withValues(alpha: 0.15);
    final iconColor = data.isDebit ? const Color(0xFFEB5757) : cs.primary;
    final amountColor = data.isDebit ? const Color(0xFFEB5757) : cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.isDebit
                  ? Icons.arrow_outward_rounded
                  : Icons.arrow_downward_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: AppTypography.titleSm(cs.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data.date,
                  style: AppTypography.bodySm(cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            data.amount,
            style: AppTypography.titleSm(amountColor),
          ),
        ],
      ),
    );
  }
}

// ─── Referral Banner ──────────────────────────────────────────────────────────

class _ReferralBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ReferralScreen(),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A1F14), Color(0xFF1A3A20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Decorative glow circle
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'REFERRAL BONUS',
                            style: AppTypography.labelSm(cs.primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            text: 'Refer a friend and get ',
                            style: AppTypography.titleMd(Colors.white),
                            children: [
                              TextSpan(
                                text: '₦2,500',
                                style: AppTypography.titleMd(cs.primary),
                              ),
                              TextSpan(
                                text: ' bonus',
                                style: AppTypography.titleMd(Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Invite Now',
                            style: AppTypography.labelMd(cs.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.card_giftcard_rounded,
                    color: cs.primary.withValues(alpha: 0.6),
                    size: 64,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
