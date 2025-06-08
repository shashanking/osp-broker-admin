import 'package:freezed_annotation/freezed_annotation.dart';
import 'dashboard_stats.dart';
import 'activity.dart';

part 'dashboard_state.freezed.dart';

@freezed
class DashboardState with _$DashboardState {
  const factory DashboardState({
    @Default(false) bool isLoading,
    @Default([]) List<DashboardStat> stats,
    @Default([]) List<Activity> activities,
  }) = _DashboardState;

  factory DashboardState.initial() => const DashboardState();
}
