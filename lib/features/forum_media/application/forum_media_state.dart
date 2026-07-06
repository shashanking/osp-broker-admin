import '../domain/forum_media_model.dart';

class ForumMediaState {
  final List<ForumMediaModel> items;
  final bool isLoading;
  final String? error;

  const ForumMediaState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  ForumMediaState copyWith({
    List<ForumMediaModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return ForumMediaState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
