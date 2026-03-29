import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_repositories.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../../core/widgets/ajo_nav_bar.dart';
import '../data/groups_http_api.dart';
import 'group_admin_screen.dart';

/// Joined group in recruitment: admin tooling vs member “wait & share” experience.
class UninitiatedJoinedGroupScreen extends StatefulWidget {
  const UninitiatedJoinedGroupScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isAdmin,
    required this.groupType,
    required this.monthlyCon,
    required this.initialMembers,
  });

  final String groupId;
  final String groupName;
  final bool isAdmin;
  final String groupType;
  final int monthlyCon;
  final List<GroupMember> initialMembers;

  @override
  State<UninitiatedJoinedGroupScreen> createState() =>
      _UninitiatedJoinedGroupScreenState();
}

class _UninitiatedJoinedGroupScreenState
    extends State<UninitiatedJoinedGroupScreen> {
  final _inviteCtrl = TextEditingController();
  bool _loading = false;
  late List<GroupMember> _members;

  @override
  void initState() {
    super.initState();
    _members = List<GroupMember>.from(widget.initialMembers);
  }

  @override
  void dispose() {
    _inviteCtrl.dispose();
    super.dispose();
  }

  int get _capacity => 12;

  int get _joined => _members.length;

  double get _fraction => _capacity == 0 ? 0 : _joined / _capacity;

  int get _pct => (_fraction * 100).round();

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final list = await groupsHttpApi.groupMembers(widget.groupId);
      if (!mounted) return;
      setState(() {
        _members = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
    }
  }

  Future<void> _invite() async {
    final email = _inviteCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an email address.')),
      );
      return;
    }
    try {
      await groupsHttpApi.inviteUser(
        groupId: widget.groupId,
        email: email,
      );
      if (!mounted) return;
      _inviteCtrl.clear();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite sent.')),
      );
      await _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _showInviteSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final pad = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + pad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Invite member', style: AppTypography.titleMd(Theme.of(ctx).colorScheme.onSurface)),
              const SizedBox(height: 12),
              TextField(
                controller: _inviteCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'name@example.com',
                ),
              ),
              const SizedBox(height: 16),
              AjoGradientButton(
                label: 'Send invite',
                onPressed: _invite,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyInvite() async {
    final text =
        'Join "${widget.groupName}" on Ajo — ask your admin for an invite or use the app.';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite message copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: const AjoNavBar(active: AjoTab.pools),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: _reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
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
            SliverToBoxAdapter(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : widget.isAdmin
                      ? _AdminBody(
                          groupName: widget.groupName,
                          joined: _joined,
                          capacity: _capacity,
                          fraction: _fraction,
                          pct: _pct,
                          monthlyCon: widget.monthlyCon,
                          members: _members,
                          onInviteMembers: _showInviteSheet,
                          onManageGroup: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => GroupAdminScreen(
                                  groupId: widget.groupId,
                                  groupName: widget.groupName,
                                ),
                              ),
                            );
                          },
                          onKickstart: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Kickstart is available when the group is full.',
                                ),
                              ),
                            );
                          },
                          onEmptySlotInvite: _showInviteSheet,
                        )
                      : _MemberBody(
                          groupName: widget.groupName,
                          joined: _joined,
                          capacity: _capacity,
                          fraction: _fraction,
                          pct: _pct,
                          monthlyCon: widget.monthlyCon,
                          groupType: widget.groupType,
                          members: _members,
                          onShareInvite: _copyInvite,
                        ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── Admin ────────────────────────────────────────────────────────────────────

class _AdminBody extends StatelessWidget {
  const _AdminBody({
    required this.groupName,
    required this.joined,
    required this.capacity,
    required this.fraction,
    required this.pct,
    required this.monthlyCon,
    required this.members,
    required this.onInviteMembers,
    required this.onManageGroup,
    required this.onKickstart,
    required this.onEmptySlotInvite,
  });

  final String groupName;
  final int joined;
  final int capacity;
  final double fraction;
  final int pct;
  final int monthlyCon;
  final List<GroupMember> members;
  final VoidCallback onInviteMembers;
  final VoidCallback onManageGroup;
  final VoidCallback onKickstart;
  final VoidCallback onEmptySlotInvite;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BannerCard(
            badge: 'ADMIN VIEW',
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.25),
                          cs.surfaceContainerHighest,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      groupName,
                      style: AppTypography.headlineSm(Colors.white)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Current Progress',
              style: AppTypography.titleSm(cs.onSurface)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Waiting for Members',
                  style: AppTypography.bodyMd(cs.onSurfaceVariant)),
              const Spacer(),
              Text(
                '$joined/$capacity Joined',
                style: AppTypography.labelMd(cs.primary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: cs.surfaceContainerHighest),
                  FractionallySizedBox(
                    widthFactor: fraction.clamp(0.0, 1.0),
                    child: Container(color: cs.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onInviteMembers,
                  icon: Icon(Icons.person_add_rounded, color: cs.onPrimary, size: 20),
                  label: Text('Invite Members',
                      style: AppTypography.labelMd(cs.onPrimary)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManageGroup,
                  icon: Icon(Icons.settings_rounded, color: cs.onSurface, size: 20),
                  label: Text('Manage Group',
                      style: AppTypography.labelMd(cs.onSurface)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: cs.surfaceContainerLowest,
                    foregroundColor: cs.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onKickstart,
              icon: Icon(Icons.bolt_rounded, color: cs.onSurfaceVariant, size: 20),
              label: Text('Kickstart Pool Early',
                  style: AppTypography.labelMd(cs.onSurface)),
              style: OutlinedButton.styleFrom(
                backgroundColor: cs.surfaceContainerLowest,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.payments_rounded,
                  label: 'MONTHLY CONTRIBUTION',
                  value: _fmtMoney(monthlyCon),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'CYCLE DURATION',
                  value: '$capacity Months',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Member Roster',
                  style: AppTypography.titleMd(cs.onSurface)),
              const Spacer(),
              Text('$capacity Slots Total',
                  style: AppTypography.labelSm(cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(capacity, (i) {
            if (i < members.length) {
              final m = members[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FilledMemberRow(
                  name: m.username.isNotEmpty ? m.username : m.email,
                  isAdmin: m.role.toLowerCase() == 'admin',
                  sub: 'Member',
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EmptySlotRow(onInvite: onEmptySlotInvite),
            );
          }),
        ],
      ),
    );
  }
}

// ── Member ───────────────────────────────────────────────────────────────────

class _MemberBody extends StatelessWidget {
  const _MemberBody({
    required this.groupName,
    required this.joined,
    required this.capacity,
    required this.fraction,
    required this.pct,
    required this.monthlyCon,
    required this.groupType,
    required this.members,
    required this.onShareInvite,
  });

  final String groupName;
  final int joined;
  final int capacity;
  final double fraction;
  final int pct;
  final int monthlyCon;
  final String groupType;
  final List<GroupMember> members;
  final VoidCallback onShareInvite;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIVE RECRUITMENT',
              style: AppTypography.labelSm(cs.primary)
                  .copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            groupName,
            style: AppTypography.headlineSm(cs.onSurface)
                .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Capacity',
                    style: AppTypography.titleSm(cs.onSurface)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$joined of $capacity slots filled',
                        style: AppTypography.bodyMd(cs.onSurfaceVariant),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: AppTypography.titleMd(cs.primary)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        Container(color: cs.surfaceContainerHighest),
                        FractionallySizedBox(
                          widthFactor: fraction.clamp(0.0, 1.0),
                          child: Container(color: cs.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(color: cs.primary, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.hourglass_empty_rounded, color: cs.primary, size: 22),
                    const SizedBox(width: 8),
                    Text('Pending Start',
                        style: AppTypography.titleSm(cs.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Waiting for members to join. The cycle starts once the group is full.',
                  style: AppTypography.bodySm(cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onShareInvite,
                  icon: Icon(Icons.share_rounded, color: cs.primary, size: 20),
                  label: Text('Share Invite',
                      style: AppTypography.labelMd(cs.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.payments_rounded,
                  label: 'CONTRIBUTION',
                  value: _fmtMoney(monthlyCon),
                  sub: 'Per Month',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'FREQUENCY',
                  value: 'Monthly',
                  sub: '$capacity Month Cycle',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Member Roster',
                  style: AppTypography.titleMd(cs.onSurface)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${groupType.toUpperCase()} GROUP',
                  style: AppTypography.labelSm(cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(capacity, (i) {
            if (i < members.length) {
              final m = members[i];
              final isAdm = m.role.toLowerCase() == 'admin';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MemberRosterRow(
                  name: m.username.isNotEmpty ? m.username : m.email,
                  badge: isAdm ? 'ADMIN' : 'MEMBER',
                  trailing: isAdm
                      ? Icon(Icons.verified_rounded, color: cs.primary, size: 20)
                      : Text('Joined recently',
                          style: AppTypography.labelSm(cs.onSurfaceVariant)),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EmptyMemberSlot(showInvite: false),
            );
          }),
        ],
      ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.badge,
    required this.child,
  });

  final String badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surfaceContainerLowest,
        boxShadow: AppTheme.ambientShadow(context.ajoTheme.ambientShadowColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                badge,
                style: AppTypography.labelSm(cs.onPrimary)
                    .copyWith(fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.labelSm(cs.onSurfaceVariant)
                .copyWith(fontSize: 9, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.titleMd(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.labelSm(cs.onSurfaceVariant)
                .copyWith(fontSize: 9, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.titleMd(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: AppTypography.labelSm(cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _FilledMemberRow extends StatelessWidget {
  const _FilledMemberRow({
    required this.name,
    required this.isAdmin,
    required this.sub,
  });

  final String name;
  final bool isAdmin;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primary.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTypography.titleSm(cs.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          style: AppTypography.titleSm(cs.onSurface),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ADMIN',
                          style: AppTypography.labelSm(cs.primary)
                              .copyWith(fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(sub, style: AppTypography.labelSm(cs.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
        ],
      ),
    );
  }
}

class _EmptySlotRow extends StatelessWidget {
  const _EmptySlotRow({required this.onInvite});

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        color: cs.surfaceContainerLowest.withValues(alpha: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.surfaceContainerHighest,
              child: Icon(Icons.person_outline_rounded, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Waiting for member…',
                style: AppTypography.bodySm(cs.onSurfaceVariant)
                    .copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            TextButton(
              onPressed: onInvite,
              child: Text('INVITE', style: AppTypography.labelMd(cs.primary)),
            ),
          ],
        ),
    );
  }
}

class _MemberRosterRow extends StatelessWidget {
  const _MemberRosterRow({
    required this.name,
    required this.badge,
    required this.trailing,
  });

  final String name;
  final String badge;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primary.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTypography.titleSm(cs.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTypography.titleSm(cs.onSurface),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  badge,
                  style: AppTypography.labelSm(cs.primary)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _EmptyMemberSlot extends StatelessWidget {
  const _EmptyMemberSlot({required this.showInvite});

  final bool showInvite;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        color: cs.surfaceContainerLowest.withValues(alpha: 0.4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.surfaceContainerHighest,
              child: Icon(Icons.person_outline_rounded, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Waiting for member…',
                style: AppTypography.bodySm(cs.onSurfaceVariant)
                    .copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            if (showInvite)
              TextButton(
                onPressed: () {},
                child: Text('Invite', style: AppTypography.labelMd(cs.primary)),
              ),
          ],
        ),
    );
  }
}

String _fmtMoney(int amount) {
  final s = amount.toString();
  if (s.length <= 3) return '₦$s';
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '₦$buf';
}
