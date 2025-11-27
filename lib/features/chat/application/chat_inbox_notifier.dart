import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/chat/application/chat_inbox_state.dart';
import 'package:osp_broker_admin/features/chat/domain/chat_recipient.dart';
import 'package:osp_broker_admin/features/users/data/repositories/user_repository.dart';

class ChatInboxNotifier extends StateNotifier<ChatInboxState> {
  final BaseApiService apiService;
  final UserRepository userRepository;

  ChatInboxNotifier({
    required this.apiService,
    required this.userRepository,
  }) : super(const ChatInboxState());

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
      
      for (final item in list.whereType<Map>()) {
        final json = item as Map<String, dynamic>;
        final recipientId = json['recipientId']?.toString() ?? '';
        
        print('DEBUG Processing recipient item: $json');
        print('DEBUG recipientId: $recipientId');
        print('DEBUG content: ${json['content']}');
        print('DEBUG createdAt: ${json['createdAt']}');
        
        // Fetch user profile to get the name
        String recipientName = '';
        if (recipientId.isNotEmpty) {
          try {
            final userProfile = await userRepository.fetchUserProfile(recipientId);
            if (userProfile != null) {
              recipientName = userProfile.fullName;
              print('DEBUG Fetched user profile for $recipientId: $recipientName');
            }
          } catch (e) {
            print('DEBUG Error fetching profile for $recipientId: $e');
          }
        }
        
        // Create recipient with fetched name
        final recipient = ChatRecipient(
          recipientId: recipientId,
          recipientName: recipientName,
          content: json['content']?.toString() ?? '',
          createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        );
        
        print('DEBUG Created recipient: ${recipient.recipientName} - ${recipient.content} - ${recipient.createdAt}');
        recipients.add(recipient);
      }
      
      // Sort by latest message first (descending order)
      recipients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('DEBUG parsed recipients: ${recipients.length}');
      print('DEBUG After sorting:');
      for (var i = 0; i < recipients.length; i++) {
        print('DEBUG [$i] ${recipients[i].recipientName} - ${recipients[i].content} - ${recipients[i].createdAt}');
      }
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        recipients: recipients,
      );
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
