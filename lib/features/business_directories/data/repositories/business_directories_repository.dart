import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/business_directories/domain/business_directories_model.dart' hide BusinessListResponse;
import 'package:osp_broker_admin/features/business_directories/domain/business_list_model.dart';

class BusinessDirectoriesRepository {
  final BaseApiService _apiService;

  BusinessDirectoriesRepository(this._apiService);

  /// Fetches all business categories with their associated businesses
  Future<BusinessCategoriesResponse> fetchBusinessCategories() async {
    try {
      final response = await _apiService.get('/business/category');
      return BusinessCategoriesResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load business categories: ${e.message}');
    }
  }

  /// Fetches a single business category by ID
  Future<BusinessCategory> fetchBusinessCategory(String id) async {
    try {
      final response = await _apiService.get('/business/category/$id');
      return BusinessCategory.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception('Failed to load business category: ${e.message}');
    }
  }

  /// Creates a new business category
  Future<BusinessCategory> createBusinessCategory({
    required String name,
    required String description,
  }) async {
    try {
      final response = await _apiService.post(
        '/business/category',
        data: {
          'name': name,
          'description': description,
        },
      );
      return BusinessCategory.fromJson(response.data['data']['category']);
    } on DioException catch (e) {
      throw Exception('Failed to create business category: ${e.message}');
    }
  }

  /// Updates an existing business category
  Future<BusinessCategory> updateBusinessCategory({
    required String id,
    required String name,
    required String description,
  }) async {
    try {
      final response = await _apiService.put(
        '/business/category/$id',
        data: {
          'name': name,
          'description': description,
        },
      );
      return BusinessCategory.fromJson(response.data['data']['category']);
    } on DioException catch (e) {
      throw Exception('Failed to update business category: ${e.message}');
    }
  }

  /// Fetch all businesses
  Future<BusinessListResponse> fetchAllBusinesses() async {
    try {
      log('Making request to /business endpoint...');
      final response = await _apiService.get('/business');
      
      if (response.data == null) {
        log('API response is null');
        throw Exception('Received null response from server');
      }
      
      log('API Response Type: ${response.data.runtimeType}');
      log('API Response Data: ${response.data}');
      
      // Check if the response contains 'data' field
      if (response.data is! Map<String, dynamic>) {
        log('Unexpected response format: ${response.data.runtimeType}');
        throw Exception('Invalid response format from server');
      }
      
      final responseData = response.data as Map<String, dynamic>;
      
      // Log the structure of the response data
      log('Response keys: ${responseData.keys.toList()}');
      
      // If the API wraps the response in a 'data' field
      if (responseData.containsKey('data')) {
        log('Found data key in response, parsing nested data...');
        return BusinessListResponse.fromJson(responseData);
      }
      
      // If the response is the direct data we need
      log('Parsing direct response data...');
      return BusinessListResponse.fromJson(responseData);
    } on DioException catch (e) {
      log('DioException: ${e.message}');
      log('Response data: ${e.response?.data}');
      log('Status code: ${e.response?.statusCode}');
      throw Exception('Failed to fetch businesses: ${e.message}');
    } catch (e, stackTrace) {
      log('Unexpected error: $e');
      log('Stack trace: $stackTrace');
      throw Exception('Failed to fetch businesses: $e');
    }
  }

  /// Deletes a business category
  Future<void> deleteBusinessCategory(String id) async {
    try {
      await _apiService.delete('/business/category/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete business category: ${e.message}');
    }
  }
}
