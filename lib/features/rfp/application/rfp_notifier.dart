import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/rfp/data/repositories/rfp_repository.dart';
import 'package:osp_broker_admin/features/rfp/domain/rfp_model.dart';

final rfpNotifierProvider =
    StateNotifierProvider<RfpNotifier, RfpState>((ref) {
  final repo = ref.watch(rfpRepositoryProvider);
  return RfpNotifier(repo);
});

class RfpState {
  final bool isLoading;
  final String? error;
  final List<RfpModel> rfps;
  final RfpModel? selectedRfp;

  const RfpState({
    this.isLoading = false,
    this.error,
    this.rfps = const [],
    this.selectedRfp,
  });

  RfpState copyWith({
    bool? isLoading,
    Object? error = const _Sentinel(),
    List<RfpModel>? rfps,
    Object? selectedRfp = const _Sentinel(),
  }) {
    return RfpState(
      isLoading: isLoading ?? this.isLoading,
      error: error is _Sentinel ? this.error : error as String?,
      rfps: rfps ?? this.rfps,
      selectedRfp: selectedRfp is _Sentinel
          ? this.selectedRfp
          : selectedRfp as RfpModel?,
    );
  }
}

class RfpNotifier extends StateNotifier<RfpState> {
  final RfpRepository _repo;

  RfpNotifier(this._repo) : super(const RfpState());

  Future<void> loadRfps() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.fetchRfps();
      state = state.copyWith(isLoading: false, rfps: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<RfpModel?> loadRfpById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final item = await _repo.fetchRfpById(id);
      state = state.copyWith(isLoading: false, selectedRfp: item);
      return item;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void clearSelected() {
    state = state.copyWith(selectedRfp: null);
  }
}

class _Sentinel {
  const _Sentinel();
}
