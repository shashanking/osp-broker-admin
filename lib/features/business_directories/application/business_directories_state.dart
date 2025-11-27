import 'package:osp_broker_admin/features/business_directories/domain/business_directories_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_directories_state.freezed.dart';

@freezed
class BusinessDirectoriesState with _$BusinessDirectoriesState {
  const factory BusinessDirectoriesState({
    @Default(false) bool isLoading,
    @Default(false) bool isCreating,
    @Default(false) bool isUpdating,
    @Default(false) bool isDeleting,
    String? error,
    @Default(<BusinessCategory>[]) List<BusinessCategory> categories,
    BusinessCategory? selectedCategory,
    @Default(true) bool showActiveOnly,
    @Default(false) bool showDeletedOnly,
  }) = _BusinessDirectoriesState;
  
  const BusinessDirectoriesState._();
  
  factory BusinessDirectoriesState.initial() => const BusinessDirectoriesState();
  
  /// Returns filtered categories based on current filter settings
  List<BusinessCategory> get filteredCategories {
    if (showDeletedOnly) {
      return categories.where((category) => category.isDeleted).toList();
    } else if (showActiveOnly) {
      return categories.where((category) => !category.isDeleted).toList();
    }
    return categories; // Show all if no specific filter is applied
  }
}