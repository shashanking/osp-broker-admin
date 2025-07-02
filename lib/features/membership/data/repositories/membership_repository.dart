import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import '../models/membership_plan_model.dart';

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  final baseApiService = ref.watch(baseApiServiceProvider);
  return MembershipRepository(baseApiService);
});

class MembershipRepository {
  final BaseApiService _apiService;

  MembershipRepository(this._apiService);

  Future<List<MembershipPlanModel>> fetchMembershipPlans() async {
    try {
      final response = await _apiService.get('/membership');
      final plans = (response.data['data']['membershipPlans'] as List)
          .map((e) => MembershipPlanModel.fromJson(e))
          .toList();
      return plans;
    } on DioException catch (e) {
      throw Exception('Failed to fetch membership plans: ${e.message}');
    }
  }

  Future<MembershipPlanModel> createMembershipPlan({
    required String name,
    required String description,
    required double price,
    required String billingCycle,
    required List<String> features,
    required int duration,
  }) async {
    try {
      final requestData = {
        'name': name,
        'description': description,
        'price': price,
        'billingCycle': billingCycle,
        'features': features,
        'duration': duration,
      };
      print('Creating new membership plan with data: $requestData');
      
      final response = await _apiService.post(
        '/membership',
        requireAuth: true,
        data: requestData,
      );
      
      print('Create response: ${response.data}');
      return MembershipPlanModel.fromJson(response.data['data']['membershipPlan']);
    } catch (e, stackTrace) {
      print('Error creating membership plan:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to create membership plan: ${e.toString()}');
    }
  }

  Future<void> deleteMembershipPlan(String id) async {
    try {
      print('Deleting membership plan with ID: $id');
      final response = await _apiService.delete('/membership/$id', requireAuth: true);
      print('Successfully deleted membership plan: $id');
      return response.data;
    } catch (e, stackTrace) {
      print('Error deleting membership plan:');
      print('ID: $id');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to delete membership plan: ${e.toString()}');
    }
  }

  Future<MembershipPlanModel> updateMembershipPlan({
    required String id,
    required String name,
    required String description,
    required double price,
    required String billingCycle,
    required List<String> features,
  }) async {
    try {
      print('Updating membership plan with ID: $id');
      final requestData = {
        'name': name,
        'description': description,
        'price': price,
        'billingCycle': billingCycle,
        'features': features,
      };
      print('Request data: $requestData');
      
      final response = await _apiService.put(
        '/membership/$id',
        requireAuth: true,
        data: requestData,
      );
      
      print('Update response: ${response.data}');
      return MembershipPlanModel.fromJson(response.data['data']['membershipPlan']);
    } catch (e, stackTrace) {
      print('Error updating membership plan:');
      print('ID: $id');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to update membership plan: ${e.toString()}');
    }
  }
}
