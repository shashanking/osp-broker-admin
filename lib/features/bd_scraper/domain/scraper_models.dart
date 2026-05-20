// Plain Dart models for the business-directory scraper. Kept hand-written to
// avoid build_runner churn — these only carry over from the backend JSON.

enum ScrapeJobStatus { queued, running, completed, failed, cancelled }

ScrapeJobStatus _parseJobStatus(String? s) {
  switch (s) {
    case 'QUEUED':
      return ScrapeJobStatus.queued;
    case 'RUNNING':
      return ScrapeJobStatus.running;
    case 'COMPLETED':
      return ScrapeJobStatus.completed;
    case 'FAILED':
      return ScrapeJobStatus.failed;
    case 'CANCELLED':
      return ScrapeJobStatus.cancelled;
    default:
      return ScrapeJobStatus.queued;
  }
}

enum ScrapedBusinessStatus { pending, approved, rejected, duplicate, claimed }

ScrapedBusinessStatus _parseSbStatus(String? s) {
  switch (s) {
    case 'PENDING':
      return ScrapedBusinessStatus.pending;
    case 'APPROVED':
      return ScrapedBusinessStatus.approved;
    case 'REJECTED':
      return ScrapedBusinessStatus.rejected;
    case 'DUPLICATE':
      return ScrapedBusinessStatus.duplicate;
    case 'CLAIMED':
      return ScrapedBusinessStatus.claimed;
    default:
      return ScrapedBusinessStatus.pending;
  }
}

String scrapedBusinessStatusToApi(ScrapedBusinessStatus s) {
  switch (s) {
    case ScrapedBusinessStatus.pending:
      return 'PENDING';
    case ScrapedBusinessStatus.approved:
      return 'APPROVED';
    case ScrapedBusinessStatus.rejected:
      return 'REJECTED';
    case ScrapedBusinessStatus.duplicate:
      return 'DUPLICATE';
    case ScrapedBusinessStatus.claimed:
      return 'CLAIMED';
  }
}

enum ScrapedEmailConfidence { scraped, guessed, verified, unknown }

ScrapedEmailConfidence _parseEmailConf(String? s) {
  switch (s) {
    case 'SCRAPED':
      return ScrapedEmailConfidence.scraped;
    case 'GUESSED':
      return ScrapedEmailConfidence.guessed;
    case 'VERIFIED':
      return ScrapedEmailConfidence.verified;
    default:
      return ScrapedEmailConfidence.unknown;
  }
}

class ScrapeJob {
  final String id;
  final String category;
  final String? locationState;
  final String? locationCity;
  final int targetCount;
  final ScrapeJobStatus status;
  final String? error;
  final int discoveredCount;
  final int extractedCount;
  final int savedCount;
  final int duplicateCount;
  final int braveQuotaUsed;
  final List<String> queriesUsed;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const ScrapeJob({
    required this.id,
    required this.category,
    required this.locationState,
    required this.locationCity,
    required this.targetCount,
    required this.status,
    required this.error,
    required this.discoveredCount,
    required this.extractedCount,
    required this.savedCount,
    required this.duplicateCount,
    required this.braveQuotaUsed,
    required this.queriesUsed,
    required this.startedAt,
    required this.completedAt,
    required this.createdAt,
  });

  factory ScrapeJob.fromJson(Map<String, dynamic> j) => ScrapeJob(
        id: j['id'] as String,
        category: j['category'] as String,
        locationState: j['locationState'] as String?,
        locationCity: j['locationCity'] as String?,
        targetCount: (j['targetCount'] as num?)?.toInt() ?? 25,
        status: _parseJobStatus(j['status'] as String?),
        error: j['error'] as String?,
        discoveredCount: (j['discoveredCount'] as num?)?.toInt() ?? 0,
        extractedCount: (j['extractedCount'] as num?)?.toInt() ?? 0,
        savedCount: (j['savedCount'] as num?)?.toInt() ?? 0,
        duplicateCount: (j['duplicateCount'] as num?)?.toInt() ?? 0,
        braveQuotaUsed: (j['braveQuotaUsed'] as num?)?.toInt() ?? 0,
        queriesUsed: (j['queriesUsed'] as List?)?.cast<String>() ?? const [],
        startedAt: j['startedAt'] != null ? DateTime.tryParse(j['startedAt'] as String) : null,
        completedAt: j['completedAt'] != null ? DateTime.tryParse(j['completedAt'] as String) : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class ScrapedBusiness {
  final String id;
  final String businessName;
  final String? website;
  final String? primaryDomain;
  final String? email;
  final ScrapedEmailConfidence emailConfidence;
  final String? phone;
  final List<String> altPhones;
  final Map<String, dynamic> socialLinks;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? postalCode;
  final String country;
  final String? industry;
  final String? category;
  final String? description;
  final List<String> services;
  final List<String> products;
  final String sourceUrl;
  final String? sourceDirectory;
  final double confidence;
  final List<String> flags;
  final ScrapedBusinessStatus status;
  final String? rejectionReason;
  final String? businessId;
  final String scrapeJobId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScrapedBusiness({
    required this.id,
    required this.businessName,
    required this.website,
    required this.primaryDomain,
    required this.email,
    required this.emailConfidence,
    required this.phone,
    required this.altPhones,
    required this.socialLinks,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.industry,
    required this.category,
    required this.description,
    required this.services,
    required this.products,
    required this.sourceUrl,
    required this.sourceDirectory,
    required this.confidence,
    required this.flags,
    required this.status,
    required this.rejectionReason,
    required this.businessId,
    required this.scrapeJobId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScrapedBusiness.fromJson(Map<String, dynamic> j) => ScrapedBusiness(
        id: j['id'] as String,
        businessName: j['businessName'] as String? ?? '',
        website: j['website'] as String?,
        primaryDomain: j['primaryDomain'] as String?,
        email: j['email'] as String?,
        emailConfidence: _parseEmailConf(j['emailConfidence'] as String?),
        phone: j['phone'] as String?,
        altPhones: (j['altPhones'] as List?)?.cast<String>() ?? const [],
        socialLinks: (j['socialLinks'] as Map?)?.cast<String, dynamic>() ?? const {},
        addressLine: j['addressLine'] as String?,
        city: j['city'] as String?,
        state: j['state'] as String?,
        postalCode: j['postalCode'] as String?,
        country: (j['country'] as String?) ?? 'US',
        industry: j['industry'] as String?,
        category: j['category'] as String?,
        description: j['description'] as String?,
        services: (j['services'] as List?)?.cast<String>() ?? const [],
        products: (j['products'] as List?)?.cast<String>() ?? const [],
        sourceUrl: (j['sourceUrl'] as String?) ?? '',
        sourceDirectory: j['sourceDirectory'] as String?,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
        flags: (j['flags'] as List?)?.cast<String>() ?? const [],
        status: _parseSbStatus(j['status'] as String?),
        rejectionReason: j['rejectionReason'] as String?,
        businessId: j['businessId'] as String?,
        scrapeJobId: j['scrapeJobId'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class PagedList<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  const PagedList({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });
}
