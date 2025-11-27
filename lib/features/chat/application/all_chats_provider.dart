import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/chat/application/all_chats_notifier.dart';
import 'package:osp_broker_admin/features/chat/application/all_chats_state.dart';
import 'package:osp_broker_admin/features/users/data/repositories/user_repository.dart';

final allChatsProvider = StateNotifierProvider<AllChatsNotifier, AllChatsState>(
  (ref) {
    final apiService = ref.watch(baseApiServiceProvider);
    final userRepository = UserRepository(apiService);

    return AllChatsNotifier(
      apiService: apiService,
      userRepository: userRepository,
    );
  },
);
