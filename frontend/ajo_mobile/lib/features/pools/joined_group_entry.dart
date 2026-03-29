import 'package:flutter/material.dart';

import '../../core/api/api_repositories.dart';
import '../../core/network/api_client.dart';
import 'data/groups_http_api.dart';
import 'screens/joined_group_details.dart';
import 'screens/uninitiated_joined_group_screen.dart';

/// Recruitment capacity before the pool is treated as “started” in the UI.
/// Aligns with the 12-slot designs; adjust when the API exposes capacity.
const int kGroupRecruitmentCapacity = 12;

/// Opens the correct joined-group experience: recruitment (uninitiated) vs active cycle (initiated).
Future<void> openJoinedGroupDetail(
  BuildContext context, {
  required String groupId,
  required String groupName,
  required String role,
  required String groupType,
  int monthlyCon = 0,
}) async {
  List<GroupMember> members;
  try {
    members = await groupsHttpApi.groupMembers(groupId);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not load group: ${e is ApiException ? e.message : e}')),
    );
    return;
  }
  if (!context.mounted) return;

  final initiated = members.length >= kGroupRecruitmentCapacity;

  if (initiated) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => JoinedGroupDetailScreen(
          state: JoinedGroupState.active,
          groupName: groupName,
        ),
      ),
    );
  } else {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UninitiatedJoinedGroupScreen(
          groupId: groupId,
          groupName: groupName,
          isAdmin: role.toLowerCase() == 'admin',
          groupType: groupType,
          monthlyCon: monthlyCon,
          initialMembers: members,
        ),
      ),
    );
  }
}
