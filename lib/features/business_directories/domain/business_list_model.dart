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
  // Real / scraped business records frequently have null or missing fields
  // (no slogan, no founded year, unclaimed = no owner/admin, etc.). Every field
  // below defaults so a single null never breaks parsing of the whole list.
  const factory BusinessModel({
    @Default('') String id,
    @Default(false) bool authorizedUser,
    @Default(false) bool isBanned,
    @Default('') String businessName,
    @Default('') String slogan,
    @Default('') String mission,
    @Default('') String industry,
    @Default(false) bool isIsp,
    @Default(<String>[]) List<String> products,
    @Default(<String>[]) List<String> services,
    @Default('') String companyType,
    @Default('') String foundedYear,
    @Default('') String history,
    // Optional: scraped/unclaimed businesses have no HQ location yet, and the
    // owner fills it on claim. Null or partial values must not break parsing.
    HQLocation? hqLocation,
    @Default(<String>[]) List<String> servingAreas,
    @Default(<String>[]) List<String> keyPeople,
    @Default(<String>[]) List<String> ownership,
    @Default('') String lastYearRevenue,
    @Default(0) int employeeCount,
    @Default(<String>[]) List<String> acquisitions,
    @Default(<String>[]) List<String> strategicPartners,
    @Default('') String saleDeckUrl,
    @Default(<String>[]) List<String> websiteLinks,
    @Default('') String accountOwnerUsername,
    @Default('') String businessAdminId,
    @Default('') String businessCategoryId,
    @Default(<Representative>[]) List<Representative> representative,
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
    @Default('') String businessId,
  }) = _Representative;

  factory Representative.fromJson(Map<String, dynamic> json) =>
      _$RepresentativeFromJson(json);
}
