import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/business_directories/application/business_directories_state.dart';

import '../data/repositories/business_directories_repository.dart';
import '../domain/business_list_model.dart';
import '../domain/business_directories_model.dart';

class BusinessDirectoriesNotifier extends StateNotifier<BusinessDirectoriesState> {
  final BusinessDirectoriesRepository _repository;

  BusinessDirectoriesNotifier(this._repository) : super(BusinessDirectoriesState.initial());

  /// Loads all business categories
  Future<void> loadBusinessCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.fetchBusinessCategories();
      state = state.copyWith(
        categories: response.data.categories,
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

  /// Loads a single business category by ID
  Future<void> loadBusinessCategory(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final category = await _repository.fetchBusinessCategory(id);
      state = state.copyWith(
        selectedCategory: category,
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

  /// Creates a new business category
  Future<BusinessCategory> createBusinessCategory({
    required String name,
    required String description,
  }) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final newCategory = await _repository.createBusinessCategory(
        name: name,
        description: description,
      );
      
      state = state.copyWith(
        categories: [...state.categories, newCategory],
        isCreating: false,
      );
      
      return newCategory;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isCreating: false,
      );
      rethrow;
    }
  }

  /// Updates an existing business category
  Future<BusinessCategory> updateBusinessCategory({
    required String id,
    required String name,
    required String description,
  }) async {
    state = state.copyWith(isUpdating: true, error: null);
    try {
      final updatedCategory = await _repository.updateBusinessCategory(
        id: id,
        name: name,
        description: description,
      );
      
      state = state.copyWith(
        categories: state.categories
            .map((category) => category.id == id ? updatedCategory : category)
            .toList(),
        selectedCategory: state.selectedCategory?.id == id 
            ? updatedCategory 
            : state.selectedCategory,
        isUpdating: false,
      );
      
      return updatedCategory;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isUpdating: false,
      );
      rethrow;
    }
  }

  /// Deletes a business category
  Future<void> deleteBusinessCategory(String id) async {
    state = state.copyWith(isDeleting: true, error: null);
    try {
      await _repository.deleteBusinessCategory(id);
      
      state = state.copyWith(
        categories: state.categories.where((category) => category.id != id).toList(),
        selectedCategory: state.selectedCategory?.id == id 
            ? null 
            : state.selectedCategory,
        isDeleting: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isDeleting: false,
      );
      rethrow;
    }
  }

  /// Selects a category
  void selectCategory(BusinessCategory? category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Clears any error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Sets filter to show only active categories
  void showActiveOnly() {
    state = state.copyWith(showActiveOnly: true, showDeletedOnly: false);
  }

  /// Sets filter to show only deleted categories
  void showDeletedOnly() {
    state = state.copyWith(showActiveOnly: false, showDeletedOnly: true);
  }

  /// Sets filter to show all categories
  void showAllCategories() {
    state = state.copyWith(showActiveOnly: false, showDeletedOnly: false);
  }

  /// Soft deletes a business category (sets isDeleted to true)
  Future<void> softDeleteBusinessCategory(String id) async {
    state = state.copyWith(isDeleting: true, error: null);
    try {
      await _repository.softDeleteBusinessCategory(id);
      
      // Update the category in the state to reflect the soft delete
      state = state.copyWith(
        categories: state.categories.map((category) {
          if (category.id == id) {
            return category.copyWith(isDeleted: true);
          }
          return category;
        }).toList(),
        selectedCategory: state.selectedCategory?.id == id 
            ? null 
            : state.selectedCategory,
        isDeleting: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isDeleting: false,
      );
      rethrow;
    }
  }

  /// Restores a soft deleted business category (sets isDeleted to false)
  Future<void> restoreBusinessCategory(String id) async {
    state = state.copyWith(isUpdating: true, error: null);
    try {
      await _repository.restoreBusinessCategory(id);
      
      // Update the category in the state to reflect the restore
      state = state.copyWith(
        categories: state.categories.map((category) {
          if (category.id == id) {
            return category.copyWith(isDeleted: false);
          }
          return category;
        }).toList(),
        isUpdating: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isUpdating: false,
      );
      rethrow;
    }
  }

  /// Fetches all businesses
  Future<List<BusinessModel>> fetchAllBusinesses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.fetchAllBusinesses();
      state = state.copyWith(isLoading: false);
      return response.businesses;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  /// Verifies a business by ID
  Future<void> verifyBusiness(String businessId) async {
    try {
      // keep state non-blocking for UI list; just clear error
      state = state.copyWith(error: null);
      await _repository.verifyBusiness(businessId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to verify business: ${e.toString()}');
      rethrow;
    }
  }

  /// Permanently deletes a business.
  Future<void> deleteBusiness(String businessId) async {
    try {
      state = state.copyWith(error: null);
      await _repository.deleteBusiness(businessId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete business: ${e.toString()}');
      rethrow;
    }
  }

  /// Bans a business (soft delete — hidden from all user-facing views).
  Future<void> banBusiness(String businessId) async {
    try {
      state = state.copyWith(error: null);
      await _repository.banBusiness(businessId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to ban business: ${e.toString()}');
      rethrow;
    }
  }

  /// Unbans a business.
  Future<void> unbanBusiness(String businessId) async {
    try {
      state = state.copyWith(error: null);
      await _repository.unbanBusiness(businessId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to unban business: ${e.toString()}');
      rethrow;
    }
  }
}

// Provider for the notifier
final businessDirectoriesNotifierProvider =
    StateNotifierProvider<BusinessDirectoriesNotifier, BusinessDirectoriesState>(
  (ref) {
    final repository = BusinessDirectoriesRepository(
      ref.read(baseApiServiceProvider),
    );
    return BusinessDirectoriesNotifier(repository);
  },
);
