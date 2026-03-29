import '../../../core/network/api_client.dart';

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.monthlyCon,
  });

  final String id;
  final String name;
  final String? description;
  final String type;
  final int monthlyCon;

  factory GroupSummary.fromJson(Map<String, dynamic> m) {
    return GroupSummary(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      description: m['description']?.toString(),
      type: m['type']?.toString() ?? '',
      monthlyCon: (m['monthly_con'] as num?)?.toInt() ?? 0,
    );
  }
}

class MyMembership {
  const MyMembership({
    required this.groupId,
    required this.name,
    required this.type,
    required this.role,
  });

  final String groupId;
  final String name;
  final String type;
  final String role;

  factory MyMembership.fromJson(Map<String, dynamic> m) {
    return MyMembership(
      groupId: m['group_id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      type: m['type']?.toString() ?? '',
      role: m['role']?.toString() ?? 'member',
    );
  }
}

class GroupInvite {
  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.status,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String status;

  factory GroupInvite.fromJson(Map<String, dynamic> m) {
    return GroupInvite(
      id: m['id']?.toString() ?? '',
      groupId: m['group_id']?.toString() ?? '',
      groupName: m['group_name']?.toString() ?? '',
      status: m['status']?.toString() ?? '',
    );
  }
}

class GroupMember {
  const GroupMember({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
  });

  final String userId;
  final String username;
  final String email;
  final String role;

  factory GroupMember.fromJson(Map<String, dynamic> m) {
    return GroupMember(
      userId: m['user_id']?.toString() ?? '',
      username: m['username']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      role: m['role']?.toString() ?? 'member',
    );
  }
}

class JoinRequest {
  const JoinRequest({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
  });

  final String id;
  final String userId;
  final String username;
  final String email;

  factory JoinRequest.fromJson(Map<String, dynamic> m) {
    return JoinRequest(
      id: m['id']?.toString() ?? '',
      userId: m['user_id']?.toString() ?? '',
      username: m['username']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
    );
  }
}

class GroupsHttpApi {
  GroupsHttpApi({required this.client});

  final ApiClient client;

 
Future<List<GroupSummary>> searchGroups({required String q}) async {
  final res = await client.getJson(
    '/groups',
    query: <String, String>{'q': q},
  );

  // Robust parsing: handles {"data": [...]} OR direct [...]
  dynamic rawList;
  if (res is Map<String, dynamic> && res.containsKey('data')) {
    rawList = res['data'];
  } else if (res is List) {
    rawList = res;
  } else {
    rawList = const <dynamic>[];
  }

  return (rawList as List<dynamic>)
      .whereType<Map<String, dynamic>>()
      .map<GroupSummary>(GroupSummary.fromJson)
      .toList();
}

  Future<GroupSummary> createGroup({
    required String name,
    required String description,
    required String type,
    required int monthlyCon,
  }) async {
    final res = await client.postJson(
      '/groups',
      body: <String, dynamic>{
        'name': name,
        'description': description,
        'type': type,
        'monthly_con': monthlyCon,
      },
    );
    return GroupSummary.fromJson(res);
  }

  Future<void> requestJoinGroup({required String groupId}) async {
    await client.postJsonNoBody('/groups/$groupId/request');
  }

  Future<List<MyMembership>> myGroups() async {
    final res = await client.getJson('/groups/me');
    dynamic rawList;
    if (res is Map<String, dynamic> && res.containsKey('data')) {
    rawList = res['data'];
  } else if (res is List) {
    rawList = res;
  } else {
    rawList = const <dynamic>[];
  }
    return (rawList as List<dynamic>).whereType<Map<String, dynamic>>().map(MyMembership.fromJson).toList();
  }

  Future<List<GroupInvite>> myInvites() async {
    final res = await client.getJson('/groups/me/invites');
    final list = res is List ? res : const <dynamic>[];
    return list.whereType<Map<String, dynamic>>().map(GroupInvite.fromJson).toList();
  }

  Future<void> acceptInvite(String requestId) async {
    await client.postJsonNoBody('/groups/me/invites/$requestId/accept');
  }

  Future<void> declineInvite(String requestId) async {
    await client.postJsonNoBody('/groups/me/invites/$requestId/decline');
  }

  Future<void> inviteUser({
    required String groupId,
    String? email,
    String? username,
  }) async {
    await client.postJson(
      '/groups/$groupId/invite',
      body: <String, dynamic>{
        if (email != null && email.isNotEmpty) 'email': email,
        if (username != null && username.isNotEmpty) 'username': username,
      },
    );
  }

  Future<List<GroupMember>> groupMembers(String groupId) async {
    final res = await client.getJson('/groups/$groupId/members');
    final list = res is List ? res : const <dynamic>[];
    return list.whereType<Map<String, dynamic>>().map(GroupMember.fromJson).toList();
  }

  Future<List<JoinRequest>> joinRequests(String groupId) async {
    final res = await client.getJson('/groups/$groupId/requests');
    final list = res is List ? res : const <dynamic>[];
    return list.whereType<Map<String, dynamic>>().map(JoinRequest.fromJson).toList();
  }

  Future<void> approveRequest(String groupId, String requestId) async {
    await client.postJsonNoBody('/groups/$groupId/requests/$requestId/approve');
  }

  Future<void> rejectRequest(String groupId, String requestId) async {
    await client.postJsonNoBody('/groups/$groupId/requests/$requestId/reject');
  }

  Future<void> leaveGroup(String groupId) async {
    await client.postJsonNoBody('/groups/$groupId/leave');
  }
}