import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_list_model.freezed.dart';
part 'business_list_model.g.dart';

@freezed
class BusinessListResponse with _$BusinessListResponse {
  const factory BusinessListResponse({
    required List<BusinessModel> businesses,
  }) = _BusinessListResponse;

  factory BusinessListResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessListResponseFromJson(json['data'] ?? json);
}

@freezed
class BusinessModel with _$BusinessModel {
  const factory BusinessModel({
    required String id,
    required bool authorizedUser,
    required String businessName,
    required String slogan,
    required String mission,
    required String industry,
    required bool isIsp,
    required List<String> products,
    required List<String> services,
    required String companyType,
    required String foundedYear,
    required String history,
    // Optional: scraped/unclaimed businesses have no HQ location yet, and the
    // owner fills it on claim. Null or partial values must not break parsing.
    HQLocation? hqLocation,
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
    required List<Representative> representative,
    // _count is ignored as per instruction
  }) = _BusinessModel;

  factory BusinessModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessModelFromJson(json);
}

@freezed
class HQLocation with _$HQLocation {
  const factory HQLocation({
    @Default('') String city,
    @Default('') String country,
    @Default('') String address,
  }) = _HQLocation;

  factory HQLocation.fromJson(Map<String, dynamic> json) =>
      _$HQLocationFromJson(json);
}

@freezed
class Representative with _$Representative {
  const factory Representative({
    required String businessId,
  }) = _Representative;

  factory Representative.fromJson(Map<String, dynamic> json) =>
      _$RepresentativeFromJson(json);
}
