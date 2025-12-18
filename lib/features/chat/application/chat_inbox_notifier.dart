import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/chat/application/chat_inbox_state.dart';
import 'package:osp_broker_admin/features/chat/domain/chat_recipient.dart';
import 'package:osp_broker_admin/features/users/data/repositories/user_repository.dart';

class ChatInboxNotifier extends StateNotifier<ChatInboxState> {
  final BaseApiService apiService;
  final UserRepository userRepository;

  final Map<String, String> _recipientNameCache = {};

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Map) {
      final maybe = value[r'$date'];
      if (maybe is String) {
        return DateTime.tryParse(maybe) ?? DateTime.now();
      }
    }
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  ChatInboxNotifier({
    required this.apiService,
    required this.userRepository,
  }) : super(const ChatInboxState());

  Future<void> _hydrateMissingRecipientNames(Set<String> recipientIds) async {
    final idsToFetch = recipientIds
        .where((id) => id.isNotEmpty && !_recipientNameCache.containsKey(id))
        .toList();

    if (idsToFetch.isEmpty) return;

    try {
      await Future.wait(
        idsToFetch.map((recipientId) async {
          try {
            final userProfile =
                await userRepository.fetchUserProfile(recipientId);
            if (userProfile != null && userProfile.fullName.isNotEmpty) {
              _recipientNameCache[recipientId] = userProfile.fullName;
            }
          } catch (_) {
            // ignore
          }
        }),
      );
    } catch (_) {
      // ignore
    }

    // Update current recipients in state with any newly cached names.
    final updated = state.recipients
        .map(
          (r) => ChatRecipient(
            recipientId: r.recipientId,
            recipientName: (r.recipientName.isNotEmpty)
                ? r.recipientName
                : (_recipientNameCache[r.recipientId] ?? r.recipientName),
            content: r.content,
            createdAt: r.createdAt,
          ),
        )
        .toList();

    state = state.copyWith(recipients: updated);
  }

  Future<void> fetchRecipients({bool isRefresh = false}) async {
    // Use isRefreshing for pull-to-refresh, isLoading for initial load
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final res = await apiService.get('/chat/recipients');
      print('DEBUG fetchRecipients response: ${res.data}');

      final list = (res.data['data'] as List?) ?? const [];
      print('DEBUG recipients list length: ${list.length}');

      // Parse recipients from API response
      final recipients = <ChatRecipient>[];

      final Set<String> recipientIds = {};

      for (final item in list.whereType<Map>()) {
        final json = item as Map<String, dynamic>;
        final recipientId = json['recipientId']?.toString() ?? '';
        recipientIds.add(recipientId);

        print('DEBUG Processing recipient item: $json');
        print('DEBUG recipientId: $recipientId');
        print('DEBUG content: ${json['content']}');
        print('DEBUG createdAt: ${json['createdAt']}');

        final cachedName = _recipientNameCache[recipientId];
        final apiName = json['recipientName']?.toString() ?? '';
        final recipientName = (cachedName != null && cachedName.isNotEmpty)
            ? cachedName
            : apiName;

        if (recipientName.isNotEmpty) {
          _recipientNameCache[recipientId] = recipientName;
        }

        // Create recipient with fetched name
        final recipient = ChatRecipient(
          recipientId: recipientId,
          recipientName: recipientName,
          content: json['content']?.toString() ?? '',
          createdAt: _parseDate(json['createdAt']),
        );

        print(
            'DEBUG Created recipient: ${recipient.recipientName} - ${recipient.content} - ${recipient.createdAt}');
        recipients.add(recipient);
      }

      // Sort by latest message first (descending order)
      recipients.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('DEBUG parsed recipients: ${recipients.length}');
      print('DEBUG After sorting:');
      for (var i = 0; i < recipients.length; i++) {
        print(
            'DEBUG [$i] ${recipients[i].recipientName} - ${recipients[i].content} - ${recipients[i].createdAt}');
      }
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        recipients: recipients,
      );

      // Fetch any missing recipient names in parallel without blocking UI.
      unawaited(_hydrateMissingRecipientNames(recipientIds));
    } catch (e) {
      print('DEBUG fetchRecipients error: $e');
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }
}
