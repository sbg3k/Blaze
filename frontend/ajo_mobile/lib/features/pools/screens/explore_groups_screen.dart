import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/api/api_repositories.dart';
import '../../../core/network/api_client.dart';
import '../models/group_model.dart';
import '../data/groups_http_api.dart';
import '../joined_group_entry.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import '../../profile/screens/notifications_screen.dart';

class ExploreGroupsScreen extends StatefulWidget {
  const ExploreGroupsScreen({super.key});

  @override
  State<ExploreGroupsScreen> createState() => _ExploreGroupsScreenState();
}

class _ExploreGroupsScreenState extends State<ExploreGroupsScreen> {
  int _filterIndex = 0;

  static const _filters = ['All', 'Real Estate', 'Travel', 'Business', 'Family'];

  bool _loading = true;
  String? _error;
  List<GroupData> _groups = const [];
  List<GroupInvite> _invites = const [];
  List<MyMembership> _myGroups = const [];

  static const _queryByFilter = <int, String>{
    0: 'a', // All
    1: 'real',
    2: 'travel',
    3: 'business',
    4: 'family',
  };

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final q = _queryByFilter[_filterIndex] ?? 'a';
      final summaries = await groupsHttpApi.searchGroups(q: q);

      // Keep discovery resilient: secondary calls should not blank the whole screen.
      List<GroupInvite> invites = const [];
      List<MyMembership> myGroups = const [];
      try {
        invites = await groupsHttpApi.myInvites();
      } catch (_) {}
      try {
        myGroups = await groupsHttpApi.myGroups();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _groups = summaries.map(_mapSummaryToUi).toList();
        _invites = invites;
        _myGroups = myGroups;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _groups = const [];
        _invites = const [];
        _myGroups = const [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  GroupData _mapSummaryToUi(GroupSummary summary) {
    final type = summary.type.toLowerCase();
    return GroupData(
      id: summary.id,
      name: summary.name,
      description: summary.description,
      type: summary.type,
      members: 0,
      capacityFraction: 0.5,
      target: '₦0',
      tag: type.isNotEmpty ? summary.type.toUpperCase() : 'GROUP',
      tagColor: _tagColorForType(type),
      icon: _iconForType(type),
    );
  }

  IconData _iconForType(String type) {
    if (type.contains('real')) return Icons.apartment_rounded;
    if (type.contains('travel')) return Icons.beach_access_rounded;
    if (type.contains('business')) return Icons.business_center_rounded;
    if (type.contains('family')) return Icons.family_restroom_rounded;
    return Icons.groups_rounded;
  }

  Color _tagColorForType(String type) {
    if (type.contains('real')) return const Color(0xFF19E619);
    if (type.contains('travel')) return Colors.blue;
    if (type.contains('business')) return Colors.orange;
    if (type.contains('family')) return Colors.purple;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: SafeArea(
        child: RefreshIndicator(
          color: cs.primary,
          onRefresh: _fetchGroups,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            // ── App bar ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Explore Groups',
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

            // ── Search bar ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.search_rounded,
                          color: cs.onSurfaceVariant, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Search groups by name or interest',
                        style: AppTypography.bodyMd(cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Filter chips ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  itemCount: _filters.length,
                  itemBuilder: (context, i) {
                    final active = i == _filterIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _filterIndex = i);
                        _fetchGroups();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 7),
                        decoration: BoxDecoration(
                          color: active
                              ? cs.primary
                              : cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _filters[i],
                          style: AppTypography.labelMd(
                            active ? cs.onPrimary : cs.onSurfaceVariant,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Group cards ─────────────────────────────────────────────
            if (_invites.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _InviteCard(
                    invite: _invites.first,
                    onAccept: () async {
                      await groupsHttpApi.acceptInvite(_invites.first.id);
                      await _fetchGroups();
                    },
                    onDecline: () async {
                      await groupsHttpApi.declineInvite(_invites.first.id);
                      await _fetchGroups();
                    },
                  ),
                ),
              ),
            if (_myGroups.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Groups',
                        style: AppTypography.titleMd(cs.onSurface),
                      ),
                      const SizedBox(height: 8),
                      ..._myGroups.take(3).map(
                            (g) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(g.name),
                              subtitle: Text(g.role.toUpperCase()),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => openJoinedGroupDetail(
                                context,
                                groupId: g.groupId,
                                groupName: g.name,
                                role: g.role,
                                groupType: g.type,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 32, 20, 100),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        style: AppTypography.bodyMd(
                          ThemeData.light().colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _fetchGroups,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GroupCard(
                        group: _groups[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(group: _groups[i]),
                          ),
                        ),
                        onInterested: () async {
                          final id = _groups[i].id;
                          if (id == null || id.isEmpty) return;
                          final isMine = _myGroups.any((g) => g.groupId == id);
                          if (isMine) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You cannot join a group you created.'),
                              ),
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
                    childCount: _groups.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  final GroupInvite invite;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invite: ${invite.groupName}', style: AppTypography.titleSm(cs.onSurface)),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: onDecline, child: const Text('Decline')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: onAccept, child: const Text('Accept')),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Group card (public — reused in home screen "See All") ────────────────────

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
    required this.onInterested,
  });
  final GroupData group;
  final VoidCallback onTap;
  final VoidCallback onInterested;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ajoTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.ambientShadow(ext.ambientShadowColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Illustration area
            Stack(
              children: [
                Container(
                  height: 140,
                  color: cs.surfaceContainerHigh,
                  child: Center(
                    child: Icon(
                      group.icon,
                      size: 60,
                      color: cs.primary.withValues(alpha: 0.30),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: group.tagColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      group.tag,
                      style: AppTypography.labelSm(
                        group.tagColor.computeLuminance() > 0.4
                            ? Colors.black
                            : Colors.white,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: AppTypography.titleMd(cs.onSurface)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.group_outlined,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${group.members} members • '
                        '${(group.capacityFraction * 100).toInt()}% full',
                        style: AppTypography.bodySm(cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.savings_outlined,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Target: ${group.target}',
                        style: AppTypography.bodySm(cs.onSurfaceVariant),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onInterested,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Interested',
                            style: AppTypography.labelMd(cs.onPrimary)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
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
