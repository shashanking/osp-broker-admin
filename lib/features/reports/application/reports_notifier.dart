import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/reports/data/repositories/reports_repository.dart';
import 'package:osp_broker_admin/features/reports/domain/flagged_content_report.dart';

final reportsNotifierProvider =
    StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  return ReportsNotifier(repo);
});

class ReportsState {
  final bool isLoading;
  final String? error;
  final List<FlaggedContentReport> reports;
  final FlaggedContentReport? selectedReport;

  ReportsState({
    this.isLoading = false,
    this.error,
    this.reports = const [],
    this.selectedReport,
  });

  ReportsState copyWith({
    bool? isLoading,
    Object? error = const _Sentinel(),
    List<FlaggedContentReport>? reports,
    Object? selectedReport = const _Sentinel(),
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      error: error is _Sentinel ? this.error : error as String?,
      reports: reports ?? this.reports,
      selectedReport: selectedReport is _Sentinel
          ? this.selectedReport
          : selectedReport as FlaggedContentReport?,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsRepository _repository;

  ReportsNotifier(this._repository) : super(ReportsState());

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repository.fetchReports();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(isLoading: false, reports: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<FlaggedContentReport?> loadReportById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final item = await _repository.fetchReportById(id);
      state = state.copyWith(isLoading: false, selectedReport: item);
      return item;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void clearSelected() {
    state = state.copyWith(selectedReport: null);
  }
}

class _Sentinel {
  const _Sentinel();
}
