import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'business_directories_model.freezed.dart';
part 'business_directories_model.g.dart';

/// Response model for business categories API
@freezed
class BusinessCategoriesResponse with _$BusinessCategoriesResponse {
  const factory BusinessCategoriesResponse({
    required bool success,
    required String message,
    required BusinessCategoriesData data,
  }) = _BusinessCategoriesResponse;

  factory BusinessCategoriesResponse.fromJson(Map<String, dynamic> json) => 
      _$BusinessCategoriesResponseFromJson(json);
}

/// Data wrapper for business categories
@freezed
class BusinessCategoriesData with _$BusinessCategoriesData {
  const factory BusinessCategoriesData({
    required List<BusinessCategory> categories,
  }) = _BusinessCategoriesData;

  factory BusinessCategoriesData.fromJson(Map<String, dynamic> json) => 
      _$BusinessCategoriesDataFromJson(json);
}

/// Business category model
@freezed
class BusinessCategory with _$BusinessCategory {
  const factory BusinessCategory({
    required String id,
    required String name,
    required String description,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(<BusinessItem>[]) List<BusinessItem> business,
  }) = _BusinessCategory;

  factory BusinessCategory.fromJson(Map<String, dynamic> json) => 
      _$BusinessCategoryFromJson(json);
}

/// Simplified business item model (for listing in categories)
@freezed
class BusinessItem with _$BusinessItem {
  const factory BusinessItem({
    required String id,
    @JsonKey(name: 'businessName') required String name,
  }) = _BusinessItem;

  factory BusinessItem.fromJson(Map<String, dynamic> json) => 
      _$BusinessItemFromJson(json);
}

// Extension to get business count and category status
// This provides a convenient way to get the count of businesses in a category
extension BusinessCategoryX on BusinessCategory {
  int get businessCount => business.length;
  
  /// Returns true if the category is active (not deleted)
  bool get isActive => !isDeleted;
  
  /// Returns the status text for the category
  String get statusText => isDeleted ? 'Deleted' : 'Active';
  
  /// Returns the status color for the category
  Color get statusColor => isDeleted 
      ? const Color(0xFFFFEBEE)  // Light red for deleted
      : const Color(0xFFE8F5E9); // Light green for active
      
  /// Returns the status text color for the category
  Color get statusTextColor => isDeleted 
      ? const Color(0xFFD32F2F)  // Red text for deleted
      : const Color(0xFF2E7D32); // Green text for active
}

/// Response model for business list API
@freezed
class BusinessListResponse with _$BusinessListResponse {
  const factory BusinessListResponse({
    required bool success,
    required String message,
    required BusinessListData data,
  }) = _BusinessListResponse;

  factory BusinessListResponse.fromJson(Map<String, dynamic> json) => 
      _$BusinessListResponseFromJson(json);
}

@freezed
class BusinessListData with _$BusinessListData {
  const factory BusinessListData({
    required List<Business> businesses,
  }) = _BusinessListData;

  factory BusinessListData.fromJson(Map<String, dynamic> json) => 
      _$BusinessListDataFromJson(json);
}

@freezed
class Business with _$Business {
  const factory Business({
    required String id,
    bool? authorizedUser,
    required String businessName,
    required String slogan,
    required String mission,
    required String industry,
    @Default(false) bool isIsp,
    required List<String> products,
    required List<String> services,
    required String companyType,
    required String foundedYear,
    required String history,
    required BusinessLocation hqLocation,
    required List<String> servingAreas,
    required List<String> keyPeople,
    required List<String> ownership,
    required String lastYearRevenue,
    required int employeeCount,
    required List<String> acquisitions,
    required List<String> strategicPartners,
    required String saleDeckUrl,
    required List<String> websiteLinks,
    required String accountOwnerUsername,
    required String businessAdminId,
    required String businessCategoryId,
    required List<BusinessRepresentative> representative,
    @JsonKey(name: '_count') required BusinessCount count,
  }) = _Business;

  factory Business.fromJson(Map<String, dynamic> json) => 
      _$BusinessFromJson(json);
}

@freezed
class BusinessLocation with _$BusinessLocation {
  const factory BusinessLocation({
    required String city,
    required String country,
    required String address,
  }) = _BusinessLocation;

  factory BusinessLocation.fromJson(Map<String, dynamic> json) => 
      _$BusinessLocationFromJson(json);
}

@freezed
class BusinessRepresentative with _$BusinessRepresentative {
  const factory BusinessRepresentative({
    required String businessId,
  }) = _BusinessRepresentative;

  factory BusinessRepresentative.fromJson(Map<String, dynamic> json) => 
      _$BusinessRepresentativeFromJson(json);
}

@freezed
class BusinessCount with _$BusinessCount {
  const factory BusinessCount({
    required int representative,
  }) = _BusinessCount;

  factory BusinessCount.fromJson(Map<String, dynamic> json) => 
      _$BusinessCountFromJson(json);
}
