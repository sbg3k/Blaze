import 'package:flutter/material.dart';

import '../../../core/api/api_repositories.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme.dart';
import '../data/groups_http_api.dart';

class GroupAdminScreen extends StatefulWidget {
  const GroupAdminScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  State<GroupAdminScreen> createState() => _GroupAdminScreenState();
}

class _GroupAdminScreenState extends State<GroupAdminScreen> {
  final _inviteCtrl = TextEditingController();
  bool _loading = true;
  List<GroupMember> _members = const [];
  List<JoinRequest> _requests = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inviteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await Future.wait([
        groupsHttpApi.groupMembers(widget.groupId),
        groupsHttpApi.joinRequests(widget.groupId),
      ]);
      if (!mounted) return;
      setState(() {
        _members = data[0] as List<GroupMember>;
        _requests = data[1] as List<JoinRequest>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _invite() async {
    try {
      await groupsHttpApi.inviteUser(
        groupId: widget.groupId,
        email: _inviteCtrl.text.trim(),
      );
      if (!mounted) return;
      _inviteCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite sent.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.groupName} (Admin)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _inviteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Invite user email',
                    hintText: 'member@example.com',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _invite, child: const Text('Send Invite')),
                const SizedBox(height: 20),
                Text('Pending Requests', style: AppTypography.titleMd(cs.onSurface)),
                const SizedBox(height: 8),
                if (_requests.isEmpty)
                  const Text('No pending requests.')
                else
                  ..._requests.map(
                    (r) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(r.username),
                      subtitle: Text(r.email),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await groupsHttpApi.rejectRequest(widget.groupId, r.id);
                              await _load();
                            },
                            child: const Text('Reject'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await groupsHttpApi.approveRequest(widget.groupId, r.id);
                              await _load();
                            },
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Members (${_members.length})', style: AppTypography.titleMd(cs.onSurface)),
                const SizedBox(height: 8),
                ..._members.map(
                  (m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.username),
                    subtitle: Text('${m.email} • ${m.role}'),
                  ),
                ),
              ],
            ),
    );
  }
}
