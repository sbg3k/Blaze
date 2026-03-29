import 'package:flutter/material.dart';
import '../data/groups_http_api.dart';
import '../../../core/network/api_client.dart';

/// Represents the various states the Explore Groups screen can be in.
class GroupsState {
  final bool isLoading;
  final String? error;
  final List<GroupSummary> groups;
  final List<GroupInvite> invites;
  final List<MyMembership> myGroups;

  GroupsState({
    this.isLoading = false,
    this.error,
    this.groups = const [],
    this.invites = const [],
    this.myGroups = const [],
  });

  // Use a sentinel so callers can explicitly clear the error by passing
  // clearError: true, while omitting the parameter leaves it untouched.
  GroupsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<GroupSummary>? groups,
    List<GroupInvite>? invites,
    List<MyMembership>? myGroups,
  }) {
    return GroupsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      groups: groups ?? this.groups,
      invites: invites ?? this.invites,
      myGroups: myGroups ?? this.myGroups,
    );
  }
}

class ExploreGroupsController extends ValueNotifier<GroupsState> {
  final GroupsHttpApi api;

  ExploreGroupsController({required this.api}) : super(GroupsState());

  int _filterIndex = 0;
  int get filterIndex => _filterIndex;

  static const filters = ['All', 'Real Estate', 'Travel', 'Business', 'Family'];
  static const _queryByFilter = {
    0: '', 1: 'real', 2: 'travel', 3: 'business', 4: 'family',
  };

  void setFilter(int index) {
    if (_filterIndex == index) return;
    _filterIndex = index;
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    value = value.copyWith(isLoading: true, clearError: true);

    try {
      final q = _queryByFilter[_filterIndex] ?? '';

      // Parallel execution for better performance.
      // Secondary calls (invites, myGroups) are best-effort: a failure there
      // should not blank the whole screen. We use explicit typed futures so
      // the DDC/web compiler never sees a List<dynamic> return from catchError.
      final Future<List<GroupInvite>> invitesFuture = api
          .myInvites()
          .then<List<GroupInvite>>((v) => v)
          .catchError((_) => <GroupInvite>[]);

      final Future<List<MyMembership>> myGroupsFuture = api
          .myGroups()
          .then<List<MyMembership>>((v) => v)
          .catchError((_) => <MyMembership>[]);

      final groups   = await api.searchGroups(q: q);
      final invites  = await invitesFuture;
      final myGroups = await myGroupsFuture;

      value = value.copyWith(
        isLoading: false,
        groups: groups,
        invites: invites,
        myGroups: myGroups,
      );
    } on ApiException catch (e) {
      value = value.copyWith(
        isLoading: false,
        error: e.message,
        groups: const [],
        invites: const [],
        myGroups: const [],
      );
    } catch (_) {
      value = value.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
        groups: const [],
        invites: const [],
        myGroups: const [],
      );
    }
  }

  Future<void> acceptInvite(String id) async {
    await api.acceptInvite(id);
    await fetchGroups();
  }

  Future<void> declineInvite(String id) async {
    await api.declineInvite(id);
    await fetchGroups();
  }

  /// Throws [ApiException] on failure so the caller can surface a snackbar.
  Future<void> requestToJoin(String groupId) async {
    await api.requestJoinGroup(groupId: groupId);
  }
}