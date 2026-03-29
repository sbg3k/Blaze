import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/api/api_repositories.dart';
import '../../../core/theme/theme.dart';
import '../models/user_profile.dart';
import '../../auth/screens/login_screen.dart';
import '../../profile/screens/kyc_screen.dart';
import '../../profile/screens/notifications_screen.dart';
import '../../profile/screens/personal_info_screen.dart';
import '../../profile/screens/security_screen.dart';
import '../../profile/screens/support_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await profileHttpApi.getMe();
      if (!mounted) return;
      setState(() {
        _profile = me;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: CustomScrollView(
        slivers: [
     
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileHeader(profile: _profile),
                const SizedBox(height: 20),
                _ProfileStatusCard(profile: _profile, loading: _loading),
                const SizedBox(height: 16),
                _KycCard(profile: _profile),
                const SizedBox(height: 28),
                _SectionLabel(label: 'ACCOUNT SETTINGS'),
                const SizedBox(height: 12),
                _SettingsGroup(
                  items: [
                    _SettingsItemData(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Information',
                      subtitle: 'Name, Email, Phone number',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PersonalInfoScreen(),
                        ),
                      ),
                    ),
                    _SettingsItemData(
                      icon: Icons.verified_user_outlined,
                      title: 'KYC Verification',
                      subtitle: 'In Progress',
                      subtitleColor: const Color(0xFFF2994A),
                      hasDot: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const KycScreen(),
                        ),
                      ),
                    ),
                    _SettingsItemData(
                      icon: Icons.lock_outline_rounded,
                      title: 'Security & Password',
                      subtitle: '2FA, Biometrics, Pin change',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SecurityScreen(),
                        ),
                      ),
                    ),
                    _SettingsItemData(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications Settings',
                      subtitle: 'Push, Email, Transaction alerts',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionLabel(label: 'SUPPORT'),
                const SizedBox(height: 12),
                _SettingsGroup(
                  items: [
                    _SettingsItemData(
                      icon: Icons.help_outline_rounded,
                      title: 'Support & Help Center',
                      subtitle: 'FAQs, Live chat, Tickets',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SupportScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _LogoutButton(),
                const SizedBox(height: 28),
                _VersionLabel(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _AccountAppBar extends StatelessWidget {
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
                  'Ajo',
                  style: AppTypography.titleLg(cs.primary),
                ),
                const Spacer(),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.15),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: cs.primary,
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

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 102,
              height: 102,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    cs.primary,
                    cs.primary.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Avatar
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.secondaryContainer,
                border: Border.all(
                  color: cs.surfaceContainer,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: Icon(
                  Icons.person,
                  color: cs.onSecondaryContainer,
                  size: 48,
                ),
              ),
            ),
            // Verified badge
            Positioned(
              bottom: 4,
              right: -4,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary,
                  border: Border.all(
                    color: cs.surfaceContainer,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Profile',
          style: AppTypography.titleLg(cs.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          profile?.handle ?? '',
          style: AppTypography.labelSm(cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─── Profile Status Card ──────────────────────────────────────────────────────

class _ProfileStatusCard extends StatelessWidget {
  const _ProfileStatusCard({required this.profile, required this.loading});
  final UserProfile? profile;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    final progress = loading ? 0.0 : (profile?.completion ?? 0.0);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROFILE STATUS',
                      style: AppTypography.labelSm(cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toInt()}% Complete',
                      style: AppTypography.titleMd(cs.onSurface),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: cs.surfaceContainerHighest),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.secondary],
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Finish setting up to unlock all features',
            style: AppTypography.bodySm(cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── KYC Card ─────────────────────────────────────────────────────────────────

class _KycCard extends StatelessWidget {
  const _KycCard({required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const KycScreen(),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0A1F14),
              cs.primary.withValues(alpha: 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              (profile?.kyc.nextStep ?? 'verify_bvn') == 'completed' ? 'KYC Completed' : 'Complete KYC',
              style: AppTypography.titleMd(cs.primary),
            ),
            const SizedBox(height: 6),
            Text(
              (profile?.kyc.nextStep ?? 'verify_bvn') == 'completed'
                  ? 'Your identity is verified and wallet is provisioned.'
                  : 'Increase your monthly savings limit by verifying your identity.',
              style: AppTypography.bodySm(cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: AppTypography.labelSm(cs.onSurfaceVariant),
    );
  }
}

// ─── Settings Group ───────────────────────────────────────────────────────────

class _SettingsItemData {
  const _SettingsItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.hasDot = false,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final bool hasDot;
  final VoidCallback onTap;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});
  final List<_SettingsItemData> items;

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
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              _SettingsRow(item: item),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  endIndent: 0,
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.item});
  final _SettingsItemData item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: cs.onSurfaceVariant, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.titleSm(cs.onSurface),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (item.hasDot) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.subtitleColor ?? cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        item.subtitle,
                        style: AppTypography.bodySm(
                          item.subtitleColor ?? cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Logout Button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout?'),
            content: const Text('You will be signed out (mock).'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          try {
            await authHttpApi.logout();
          } catch (_) {}
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const LoginScreen(),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.logout_rounded,
              color: Color(0xFFEB5757),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: AppTypography.titleSm(const Color(0xFFEB5757)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Version Label ────────────────────────────────────────────────────────────

class _VersionLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'AJO VERSION 2.4.0 (GOLD)',
        style: AppTypography.labelSm(
          cs.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
