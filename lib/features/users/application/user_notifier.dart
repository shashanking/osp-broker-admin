import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_model.dart';
import '../data/models/user_membership_model.dart';

class UserState {
  final List<UserModel> users;
  final Map<String, List<UserMembershipModel>> userMemberships; // userId -> memberships
  final bool isLoading;
  final bool isLoadingMemberships;
  final String? error;
  final Set<String> updatingUserIds;
  final Set<String> loadingMembershipUserIds;

  UserState({
    this.users = const [],
    this.userMemberships = const {},
    this.isLoading = false,
    this.isLoadingMemberships = false,
    this.error,
    this.updatingUserIds = const {},
    this.loadingMembershipUserIds = const {},
  });

  UserState copyWith({
    List<UserModel>? users,
    Map<String, List<UserMembershipModel>>? userMemberships,
    bool? isLoading,
    bool? isLoadingMemberships,
    String? error,
    Set<String>? updatingUserIds,
    Set<String>? loadingMembershipUserIds,
  }) {
    return UserState(
      users: users ?? this.users,
      userMemberships: userMemberships ?? this.userMemberships,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMemberships: isLoadingMemberships ?? this.isLoadingMemberships,
      error: error,
      updatingUserIds: updatingUserIds ?? this.updatingUserIds,
      loadingMembershipUserIds: loadingMembershipUserIds ?? this.loadingMembershipUserIds,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final UserRepository repository;
  UserNotifier(this.repository) : super(UserState());

  Future<void> deleteUser(String userId) async {
    try {
      final success = await repository.deleteUser(userId);
      if (success) {
        final updatedUsers = state.users.where((u) => u.id != userId).toList();
        state = state.copyWith(users: updatedUsers);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> banUser(String userId) async {
    try {
      final updatedUser = await repository.banUser(userId);
      final updatedUsers = state.users
          .map((u) => u.id == updatedUser.id ? updatedUser : u)
          .toList();
      state = state.copyWith(users: updatedUsers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> fetchUsers() async {
    try {
      // Only show loading state if we don't have any data yet
      if (state.users.isEmpty) {
        state = state.copyWith(isLoading: true, error: null);
      }
      
      final users = await repository.fetchAllUsers();
      if (!mounted) return;
      
      state = state.copyWith(
        users: users,
        isLoading: false,
        error: null, // Clear any previous errors
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        error: 'Failed to fetch users: $e',
        isLoading: false,
      );
    }
  }

  Future<void> assignModerator(String userId) async {
    state = state.copyWith(updatingUserIds: {...state.updatingUserIds, userId});
    try {
      // Optimistically update the user role in the list
      final updatedUsers = state.users
          .map((u) => u.id == userId
              ? UserModel(
                  id: u.id,
                  fullName: u.fullName,
                  email: u.email,
                  role: 'moderator'.toUpperCase(),
                  phone: u.phone,
                  isBanned: u.isBanned,
                  createdAt: u.createdAt,
                  updatedAt: u.updatedAt,
                )
              : u)
          .toList();
      state = state.copyWith(users: updatedUsers);
      await repository.assignModerator(userId);
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      final newSet = {...state.updatingUserIds}..remove(userId);
      state = state.copyWith(updatingUserIds: newSet);
    }
  }

  Future<void> removeModerator(String userId) async {
    state = state.copyWith(updatingUserIds: {...state.updatingUserIds, userId});
    try {
      // Optimistically update the user role in the list
      final updatedUsers = state.users.map((u) {
        if (u.id == userId) {
          return UserModel(
            id: u.id,
            fullName: u.fullName,
            email: u.email,
            role: 'user',
            phone: u.phone,
            isBanned: u.isBanned,
            createdAt: u.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return u;
      }).toList();
      
      state = state.copyWith(users: updatedUsers);
      await repository.removeModerator(userId);
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      final newSet = {...state.updatingUserIds}..remove(userId);
      state = state.copyWith(updatingUserIds: newSet);
    }
  }

  // Membership related methods
  Future<bool> deleteUserMembership(String membershipId, String userId) async {
    try {
      state = state.copyWith(
        loadingMembershipUserIds: {...state.loadingMembershipUserIds, userId},
      );
      
      final success = await repository.deleteUserMembership(membershipId);
      
      if (success) {
        // Instead of just updating local state, refresh all memberships to ensure consistency
        await loadAllUserMemberships();
      }
      
      return success;
    } catch (e) {
      print('Error deleting membership: $e');
      rethrow;
    } finally {
      if (mounted) {
        state = state.copyWith(
          loadingMembershipUserIds: {...state.loadingMembershipUserIds}..remove(userId),
        );
      }
    }
  }

  Future<UserMembershipModel> createUserMembership({
    required String userId,
    required String membershipPlanId,
    required DateTime startDate,
    required DateTime endDate,
    String status = 'active',
  }) async {
    try {
      state = state.copyWith(
        loadingMembershipUserIds: {...state.loadingMembershipUserIds, userId},
      );

      // Create the new membership
      final newMembership = await repository.createUserMembership(
        userId: userId,
        membershipPlanId: membershipPlanId,
        startDate: startDate,
        endDate: endDate,
        status: status,
      );

      // Instead of just adding to local state, refresh all memberships to ensure consistency
      await loadAllUserMemberships();
      
      return newMembership;
    } catch (e) {
      print('Error creating membership: $e');
      rethrow;
    } finally {
      if (mounted) {
        state = state.copyWith(
          loadingMembershipUserIds: {...state.loadingMembershipUserIds}..remove(userId),
        );
      }
    }
  }

  Future<void> loadUserMemberships(String userId) async {
    if (state.loadingMembershipUserIds.contains(userId)) return;
    
    state = state.copyWith(
      loadingMembershipUserIds: {...state.loadingMembershipUserIds, userId},
    );
    
    try {
      final memberships = await repository.getUserMemberships(userId);
      state = state.copyWith(
        userMemberships: {
          ...state.userMemberships,
          userId: memberships,
        },
      );
    } catch (e) {
      // Handle error
      print('Error loading memberships: $e');
    } finally {
      state = state.copyWith(
        loadingMembershipUserIds: {...state.loadingMembershipUserIds}..remove(userId),
      );
    }
  }

  Future<void> loadAllUserMemberships() async {
    try {
      // Only show loading state if we don't have any data yet
      if (state.userMemberships.isEmpty) {
        state = state.copyWith(
          isLoadingMemberships: true,
          error: null,
        );
      }
      
      // Force fetch from server by not using cache
      final memberships = await repository.getAllUserMemberships(forceRefresh: true);
      
      if (!mounted) return;
      
      // Group memberships by userId
      final membershipsByUser = <String, List<UserMembershipModel>>{};
      for (final membership in memberships) {
        membershipsByUser.update(
          membership.userId,
          (list) => [...list, membership],
          ifAbsent: () => [membership],
        );
      }
      
      state = state.copyWith(
        userMemberships: membershipsByUser,
        isLoadingMemberships: false,
        error: null, // Clear any previous errors
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        error: 'Failed to load all memberships: ${e.toString()}',
        isLoadingMemberships: false,
      );
      rethrow; // Rethrow to handle in the UI
    }
  }

  Future<void> assignMembership({
    required String userId,
    required String membershipPlanId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      state = state.copyWith(updatingUserIds: {...state.updatingUserIds, userId});
      
      final success = await repository.assignMembership(
        userId: userId,
        membershipPlanId: membershipPlanId,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (success) {
        // Reload the user's memberships
        await loadUserMemberships(userId);
      } else {
        throw Exception('Failed to assign membership');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to assign membership: ${e.toString()}');
      rethrow;
    } finally {
      final newSet = {...state.updatingUserIds}..remove(userId);
      state = state.copyWith(updatingUserIds: newSet);
    }
  }

  Future<void> cancelMembership({
    required String userId,
    required String membershipId,
  }) async {
    try {
      state = state.copyWith(updatingUserIds: {...state.updatingUserIds, userId});
      
      final success = await repository.cancelMembership(membershipId);
      
      if (success) {
        // Remove the cancelled membership from state
        state = state.copyWith(
          userMemberships: {
            ...state.userMemberships,
            userId: state.userMemberships[userId]
                    ?.where((m) => m.id != membershipId)
                    .toList() ??
                [],
          },
        );
      } else {
        throw Exception('Failed to cancel membership');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel membership: ${e.toString()}');
      rethrow;
    } finally {
      final newSet = {...state.updatingUserIds}..remove(userId);
      state = state.copyWith(updatingUserIds: newSet);
    }
  }
}

final userNotifierProvider =
    StateNotifierProvider<UserNotifier, UserState>((ref) {
  final apiService = ref.watch(baseApiServiceProvider);
  final repo = UserRepository(apiService);
  return UserNotifier(repo);
});
