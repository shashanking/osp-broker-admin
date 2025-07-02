import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/membership_repository.dart';
import '../data/models/membership_plan_model.dart';

final membershipNotifierProvider = StateNotifierProvider<MembershipNotifier, MembershipState>((ref) {
  final repository = ref.watch(membershipRepositoryProvider);
  return MembershipNotifier(repository);
});

class MembershipState {
  final List<MembershipPlanModel> plans;
  final bool isLoading;
  final String? error;

  MembershipState({this.plans = const [], this.isLoading = false, this.error});

  MembershipState copyWith({List<MembershipPlanModel>? plans, bool? isLoading, String? error}) {
    return MembershipState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MembershipNotifier extends StateNotifier<MembershipState> {
  final MembershipRepository _repository;

  MembershipNotifier(this._repository) : super(MembershipState());

  Future<void> fetchMemberships() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plans = await _repository.fetchMembershipPlans();
      state = state.copyWith(plans: plans, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createMembership({
    required String name,
    required String description,
    required double price,
    required String billingCycle,
    required List<String> features,
    required int duration,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newPlan = await _repository.createMembershipPlan(
        name: name,
        description: description,
        price: price,
        billingCycle: billingCycle,
        features: features,
        duration: duration,
      );
      state = state.copyWith(
        plans: [newPlan, ...state.plans],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> deleteMembership(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteMembershipPlan(id);
      state = state.copyWith(
        plans: state.plans.where((plan) => plan.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> updateMembership({
    required String id,
    required String name,
    required String description,
    required double price,
    required String billingCycle,
    required List<String> features,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedPlan = await _repository.updateMembershipPlan(
        id: id,
        name: name,
        description: description,
        price: price,
        billingCycle: billingCycle,
        features: features,
      );
      state = state.copyWith(
        plans: state.plans.map((plan) =>
          plan.id == id ? updatedPlan : plan
        ).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }
}
