// Riverpod state for the scraper feature. Two main slices:
//   - scraperJobsProvider     → list of recent jobs, with auto-refresh while
//                               anything is RUNNING so the admin sees progress.
//   - scraperPendingProvider  → paginated pending review list with filters.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/bd_scraper/data/scraper_repository.dart';
import 'package:osp_broker_admin/features/bd_scraper/domain/scraper_models.dart';

// ---------- Jobs ----------

class ScraperJobsState {
  final bool loading;
  final String? error;
  final List<ScrapeJob> jobs;
  const ScraperJobsState({
    required this.loading,
    required this.error,
    required this.jobs,
  });
  factory ScraperJobsState.initial() => const ScraperJobsState(loading: false, error: null, jobs: []);
  ScraperJobsState copyWith({bool? loading, String? error, List<ScrapeJob>? jobs}) =>
      ScraperJobsState(loading: loading ?? this.loading, error: error, jobs: jobs ?? this.jobs);
}

class ScraperJobsNotifier extends StateNotifier<ScraperJobsState> {
  final ScraperRepository _repo;
  Timer? _poller;

  ScraperJobsNotifier(this._repo) : super(ScraperJobsState.initial());

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _repo.listJobs(pageSize: 30);
      state = state.copyWith(loading: false, jobs: res.items);
      _maybeStartPolling();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void _maybeStartPolling() {
    final hasRunning = state.jobs.any((j) => j.status == ScrapeJobStatus.running || j.status == ScrapeJobStatus.queued);
    if (hasRunning) {
      _poller ??= Timer.periodic(const Duration(seconds: 5), (_) => _refreshSilent());
    } else {
      _poller?.cancel();
      _poller = null;
    }
  }

  Future<void> _refreshSilent() async {
    try {
      final res = await _repo.listJobs(pageSize: 30);
      state = state.copyWith(jobs: res.items, loading: false);
      _maybeStartPolling();
    } catch (e) {
      debugPrint('jobs poll failed: $e');
    }
  }

  Future<ScrapeJob> startJob({
    required String category,
    String? state,
    String? city,
    int targetCount = 25,
  }) async {
    final job = await _repo.createJob(category: category, state: state, city: city, targetCount: targetCount);
    // optimistic prepend
    this.state = this.state.copyWith(jobs: [job, ...this.state.jobs]);
    _maybeStartPolling();
    return job;
  }
}

final scraperJobsProvider = StateNotifierProvider<ScraperJobsNotifier, ScraperJobsState>((ref) {
  return ScraperJobsNotifier(ref.watch(scraperRepositoryProvider));
});

// ---------- Pending review ----------

class ScraperPendingFilter {
  final ScrapedBusinessStatus status;
  final String? jobId;
  final String? state;
  final String? search;
  final int page;
  final int pageSize;
  const ScraperPendingFilter({
    this.status = ScrapedBusinessStatus.pending,
    this.jobId,
    this.state,
    this.search,
    this.page = 1,
    this.pageSize = 25,
  });
  ScraperPendingFilter copyWith({
    ScrapedBusinessStatus? status,
    String? jobId,
    String? state,
    String? search,
    int? page,
    int? pageSize,
    bool clearJob = false,
    bool clearState = false,
    bool clearSearch = false,
  }) {
    return ScraperPendingFilter(
      status: status ?? this.status,
      jobId: clearJob ? null : (jobId ?? this.jobId),
      state: clearState ? null : (state ?? this.state),
      search: clearSearch ? null : (search ?? this.search),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class ScraperPendingState {
  final bool loading;
  final String? error;
  final ScraperPendingFilter filter;
  final List<ScrapedBusiness> items;
  final int total;
  const ScraperPendingState({
    required this.loading,
    required this.error,
    required this.filter,
    required this.items,
    required this.total,
  });
  factory ScraperPendingState.initial() => const ScraperPendingState(
    loading: false,
    error: null,
    filter: ScraperPendingFilter(),
    items: [],
    total: 0,
  );
  ScraperPendingState copyWith({
    bool? loading,
    String? error,
    ScraperPendingFilter? filter,
    List<ScrapedBusiness>? items,
    int? total,
  }) =>
      ScraperPendingState(
        loading: loading ?? this.loading,
        error: error,
        filter: filter ?? this.filter,
        items: items ?? this.items,
        total: total ?? this.total,
      );
}

class ScraperPendingNotifier extends StateNotifier<ScraperPendingState> {
  final ScraperRepository _repo;
  ScraperPendingNotifier(this._repo) : super(ScraperPendingState.initial());

  Future<void> load([ScraperPendingFilter? newFilter]) async {
    final f = newFilter ?? state.filter;
    state = state.copyWith(loading: true, error: null, filter: f);
    try {
      final res = await _repo.listPending(
        status: f.status,
        jobId: f.jobId,
        state: f.state,
        search: f.search,
        page: f.page,
        pageSize: f.pageSize,
      );
      state = state.copyWith(loading: false, items: res.items, total: res.total);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> applyFilter(ScraperPendingFilter f) => load(f);

  Future<void> updateRecord(String id, Map<String, dynamic> patch) async {
    final updated = await _repo.updatePending(id, patch);
    state = state.copyWith(
      items: state.items.map((it) => it.id == id ? updated : it).toList(),
    );
  }

  Future<void> approve(String id, String businessCategoryId, {Map<String, dynamic>? overrides}) async {
    await _repo.approve(id, businessCategoryId: businessCategoryId, overrides: overrides);
    state = state.copyWith(items: state.items.where((it) => it.id != id).toList(), total: state.total - 1);
  }

  Future<void> reject(String id, String reason) async {
    await _repo.reject(id, reason);
    state = state.copyWith(items: state.items.where((it) => it.id != id).toList(), total: state.total - 1);
  }

  Future<List<dynamic>> bulkApprove(List<String> ids, String businessCategoryId) async {
    final results = await _repo.bulkApprove(ids, businessCategoryId);
    state = state.copyWith(items: state.items.where((it) => !ids.contains(it.id)).toList(), total: state.total - ids.length);
    return results;
  }
}

final scraperPendingProvider = StateNotifierProvider<ScraperPendingNotifier, ScraperPendingState>((ref) {
  return ScraperPendingNotifier(ref.watch(scraperRepositoryProvider));
});
