import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/api/api_repositories.dart';
import '../../../core/theme/theme.dart';
import '../../pools/data/groups_http_api.dart';
import '../../pools/joined_group_entry.dart';
import '../../pools/screens/create_group_screen.dart';
import '../../pools/screens/explore_groups_screen.dart';
import '../models/user_profile.dart';
import '../../profile/screens/kyc_screen.dart';
import 'account_screen.dart';
import 'wallet_screen.dart';
import '../../messages/screens/messages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;
  UserProfile? _profile;
  List<MyMembership> _myGroups = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadProfile();
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final profile = await profileHttpApi.getMe();
      List<MyMembership> groups = const [];
      try {
        groups = await groupsHttpApi.myGroups();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _myGroups = groups;
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showFab = _selectedIndex == 0;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              ),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 30),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _selectedIndex = i),
        children: [
          _KeptPage(
            storageKey: PageStorageKey('home_dashboard'),
            child: _HomeContent(
              profile: _profile,
              myGroups: _myGroups,
              loading: _loading,
              error: _error,
              onRetry: _loadProfile,
            ),
          ),
          _KeptPage(
            storageKey: PageStorageKey('home_explore'),
            child: ExploreGroupsScreen(),
          ),
          const _KeptPage(
            storageKey: PageStorageKey('home_wallet'),
            child: WalletScreen(),
          ),
          const _KeptPage(
            storageKey: PageStorageKey('home_accounts'),
            child: AccountScreen(),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.profile,
    required this.myGroups,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final UserProfile? profile;
  final List<MyMembership> myGroups;
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: widget.onRetry,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _GlassAppBar(profile: widget.profile),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (widget.error != null) _ErrorCard(message: widget.error!, onRetry: widget.onRetry),
                  _BalanceCard(profile: widget.profile, loading: widget.loading),
                  const SizedBox(height: 20),
                  _ProfileCompletionCard(profile: widget.profile, loading: widget.loading),
                  const SizedBox(height: 28),
                  _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  _QuickActionsGrid(),
                  const SizedBox(height: 28),
                  _SectionHeader(title: 'My Groups'),
                  const SizedBox(height: 12),
                  if (widget.loading)
                    const Center(child: CircularProgressIndicator())
                  else if (widget.myGroups.isEmpty)
                    _EmptyGroupsCard()
                  else
                    ...widget.myGroups.map(
                      (g) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MyGroupCard(
                          group: g,
                          onOpen: () => openJoinedGroupDetail(
                            context,
                            groupId: g.groupId,
                            groupName: g.name,
                            role: g.role,
                            groupType: g.type,
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Kept Page ────────────────────────────────────────────────────────────────

class _KeptPage extends StatefulWidget {
  const _KeptPage({required this.storageKey, required this.child});
  final Key storageKey;
  final Widget child;

  @override
  State<_KeptPage> createState() => _KeptPageState();
}

class _KeptPageState extends State<_KeptPage>
    with AutomaticKeepAliveClientMixin<_KeptPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return KeyedSubtree(key: widget.storageKey, child: widget.child);
  }
}

// ─── Glass App Bar ────────────────────────────────────────────────────────────

class _GlassAppBar extends StatelessWidget {
  const _GlassAppBar({this.profile});
  final UserProfile? profile;

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
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.secondaryContainer,
                  ),
                  child: Icon(Icons.person,
                      color: cs.onSecondaryContainer, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,',
                          style: AppTypography.labelSm(cs.onSurfaceVariant)),
                      Text(profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Welcome',
                          style: AppTypography.titleMd(cs.onSurface)),
                    ],
                  ),
                ),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, _, _) {
                    final isDark = themeModeNotifier.isDark(context);
                    return GestureDetector(
                      onTap: () => themeModeNotifier.toggle(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const MessagesScreen()),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.chat_bubble_outline_rounded,
                            color: cs.onSurface, size: 22),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: cs.surface, width: 1.5),
                          ),
                        ),
                      ),
                    ],
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

// ─── Shimmer Box ──────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.surfaceContainerHigh;
    final highlight = cs.onSurfaceVariant.withValues(alpha: 0.20);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final begin = Alignment(-1.0 + (2.2 * t), 0.0);
        final end = Alignment(-0.2 + (2.2 * t), 0.0);
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = widget.width == double.infinity
                ? constraints.maxWidth
                : widget.width;
            return Container(
              width: w,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                gradient: LinearGradient(
                  begin: begin,
                  end: end,
                  colors: [base, highlight, base],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.profile, this.loading = false});
  final UserProfile? profile;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    final fixed = 0.0.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts.first;
    final decPart = parts.length > 1 ? parts.last : '00';
    final intFormatted = intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );

    const cardBg1 = Color(0xFF0A1F14);
    const cardBg2 = Color(0xFF1A2E1E);
    const cardSurface = Color(0xFF152815);

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
          color: cs.primary.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: loading
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 170, height: 14, radius: 10),
                const SizedBox(height: 8),
                _ShimmerBox(width: 150, height: 10, radius: 10),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ShimmerBox(width: 18, height: 28, radius: 8),
                    const SizedBox(width: 10),
                    _ShimmerBox(width: 150, height: 44, radius: 12),
                    const SizedBox(width: 12),
                    _ShimmerBox(width: 50, height: 26, radius: 10),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    SizedBox(
                      height: 32,
                      width: 104,
                      child: Stack(
                        children: List.generate(4, (i) {
                          return Positioned(
                            left: i * 22.0,
                            child: const _ShimmerBox(
                                width: 32, height: 32, radius: 100),
                          );
                        }),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 140,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: _ShimmerBox(
                            width: 120, height: 18, radius: 10),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'THRIFT SAVINGS',
                            style: AppTypography.labelSm(cs.primary).copyWith(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Pool Balance',
                            style: AppTypography.labelSm(
                              Colors.white.withValues(alpha: 0.50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white.withValues(alpha: 0.10),
                      size: 56,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₦',
                      style: AppTypography.displaySm(cs.primary).copyWith(
                          fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      intFormatted,
                      style: AppTypography.displaySm(Colors.white).copyWith(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1),
                    ),
                    Text(
                      '.$decPart',
                      style: AppTypography.headlineSm(
                              Colors.white.withValues(alpha: 0.60))
                          .copyWith(fontSize: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    SizedBox(
                      height: 32,
                      width: 104,
                      child: Stack(
                        children: List.generate(4, (i) {
                          return Positioned(
                            left: i * 22.0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < 3
                                    ? cardSurface
                                    : cs.primary.withValues(alpha: 0.25),
                                border: Border.all(
                                    color: cardSurface, width: 2),
                              ),
                              child: i < 3
                                  ? Icon(Icons.person,
                                      size: 16,
                                      color: Colors.white
                                          .withValues(alpha: 0.70))
                                  : Center(
                                      child: Text(
                                        '+12',
                                        style: AppTypography.labelSm(
                                                cs.primary)
                                            .copyWith(fontSize: 9),
                                      ),
                                    ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profile?.wallet?.accountNumber ?? 'No wallet yet',
                                  style: AppTypography.labelMd(
                                          const Color(0xFF003919))
                                      .copyWith(
                                          fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: Color(0xFF003919)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard({required this.profile, this.loading = false});
  final UserProfile? profile;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    final progress = profile?.completion ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: loading
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _ShimmerBox(width: 190, height: 14, radius: 8),
                          SizedBox(height: 10),
                          _ShimmerBox(width: 220, height: 10, radius: 8),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _ShimmerBox(width: 36, height: 36, radius: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    _ShimmerBox(width: 120, height: 16, radius: 8),
                    Spacer(),
                    _ShimmerBox(width: 90, height: 14, radius: 8),
                  ],
                ),
                const SizedBox(height: 8),
                const ClipRRect(
                  borderRadius:
                      BorderRadius.all(Radius.circular(100)),
                  child: _ShimmerBox(
                      width: double.infinity, height: 6, radius: 100),
                ),
                const SizedBox(height: 14),
                const _ShimmerBox(
                    width: double.infinity, height: 44, radius: 10),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Complete Your Profile',
                              style: AppTypography.titleMd(cs.onSurface)),
                          const SizedBox(height: 2),
                          Text(
                            'Verify BVN and provision wallet to unlock all features.',
                            style:
                                AppTypography.bodySm(cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified_user_rounded,
                          color: cs.primary, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${(progress * 100).toInt()}% Completed',
                        style: AppTypography.labelMd(cs.primary)
                            .copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${(progress * 4).round()}/4 Steps',
                        style:
                            AppTypography.labelSm(cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: SizedBox(
                    height: 6,
                    child: Stack(children: [
                      Container(color: cs.surfaceContainerHighest),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(color: cs.primary),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const KycScreen()),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.primary),
                    ),
                    child: Text(
                      'Finish Setup Now',
                      style: AppTypography.labelLg(cs.primary)
                          .copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
            child: Text(title,
                style: AppTypography.titleLg(cs.onSurface))),
        action ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.search_rounded,
            title: 'Explore',
            subtitle: 'Join new savings pools',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const ExploreGroupsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.verified_user_outlined,
            title: 'Verify KYC',
            subtitle: 'Complete BVN verification',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const KycScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.titleMd(cs.onSurface)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: AppTypography.bodySm(cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message, style: AppTypography.bodySm(cs.onErrorContainer))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyGroupsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'You have not joined any groups yet.',
        style: AppTypography.bodyMd(cs.onSurfaceVariant),
      ),
    );
  }
}

class _MyGroupCard extends StatelessWidget {
  const _MyGroupCard({required this.group, required this.onOpen});
  final MyMembership group;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.groups_rounded, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: AppTypography.titleSm(cs.onSurface)),
                    Text(
                      '${group.type.toUpperCase()} • ${group.role.toUpperCase()}',
                      style: AppTypography.labelSm(cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BottomAppBar(
      color: cs.surfaceContainerLowest,
      elevation: 0,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.explore_outlined,
              label: 'Explore',
              selected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
            const Expanded(child: SizedBox()),
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              selected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Accounts',
              selected: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.labelSm(color)),
          ],
        ),
      ),
    );
  }
}