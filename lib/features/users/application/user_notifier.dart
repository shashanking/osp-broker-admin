import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_model.dart';

class UserState {
  final List<UserModel> users;
  final bool isLoading;
  final String? error;
  final Set<String> updatingUserIds;

  UserState(
      {this.users = const [],
      this.isLoading = false,
      this.error,
      this.updatingUserIds = const {}});

  UserState copyWith(
      {List<UserModel>? users,
      bool? isLoading,
      String? error,
      Set<String>? updatingUserIds}) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      updatingUserIds: updatingUserIds ?? this.updatingUserIds,
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await repository.fetchAllUsers();
      state = state.copyWith(users: users, isLoading: false);
      print(users.length);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
      final updatedUsers = state.users
          .map((u) => u.id == userId
              ? UserModel(
                  id: u.id,
                  fullName: u.fullName,
                  email: u.email,
                  role: 'user'.toUpperCase(),
                  phone: u.phone,
                  isBanned: u.isBanned,
                  createdAt: u.createdAt,
                  updatedAt: u.updatedAt,
                )
              : u)
          .toList();
      state = state.copyWith(users: updatedUsers);
      await repository.removeModerator(userId);
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
