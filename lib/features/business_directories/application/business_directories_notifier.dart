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
