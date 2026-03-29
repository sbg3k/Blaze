import 'package:flutter/material.dart';

import '../../../core/api/api_repositories.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme.dart';
import '../data/groups_http_api.dart';

class GroupUserScreen extends StatefulWidget {
  const GroupUserScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  @override
  State<GroupUserScreen> createState() => _GroupUserScreenState();
}

class _GroupUserScreenState extends State<GroupUserScreen> {
  bool _loading = true;
  List<GroupMember> _members = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await groupsHttpApi.groupMembers(widget.groupId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _leave() async {
    try {
      await groupsHttpApi.leaveGroup(widget.groupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You left the group.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Members (${_members.length})', style: AppTypography.titleMd(cs.onSurface)),
                const SizedBox(height: 8),
                ..._members.map(
                  (m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.username),
                    subtitle: Text('${m.email} • ${m.role}'),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _leave,
                  child: const Text('Leave Group'),
                ),
              ],
            ),
    );
  }
}
