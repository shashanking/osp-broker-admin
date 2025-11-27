import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/chat/application/all_chats_state.dart';
import 'package:osp_broker_admin/features/chat/domain/individual_chat.dart';
import 'package:osp_broker_admin/features/users/data/repositories/user_repository.dart';

class AllChatsNotifier extends StateNotifier<AllChatsState> {
  final BaseApiService apiService;
  final UserRepository userRepository;

  AllChatsNotifier({
    required this.apiService,
    required this.userRepository,
  }) : super(const AllChatsState());

  Future<void> fetchAllChats({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final res = await apiService.get('/admin/getALLIndividualChats');
      print('DEBUG fetchAllChats response: ${res.data}');

      final list = (res.data['data'] as List?) ?? const [];
      print('DEBUG all messages count: ${list.length}');

      // Group messages by conversation (unique sender-recipient pairs)
      final Map<String, Map<String, dynamic>> conversationMap = {};

      for (final item in list.whereType<Map>()) {
        final json = item as Map<String, dynamic>;
        
        final senderId = json['senderId']?.toString() ?? '';
        final recipientId = json['recipientId']?.toString() ?? '';
        final content = json['content']?.toString() ?? '';
        final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
        final isRead = json['read'] as bool? ?? true;

        if (senderId.isEmpty || recipientId.isEmpty) continue;

        // Create a unique conversation key (sorted to ensure same conversation regardless of direction)
        final List<String> ids = [senderId, recipientId]..sort();
        final conversationKey = '${ids[0]}_${ids[1]}';

        // Check if this conversation exists and if this message is newer
        if (!conversationMap.containsKey(conversationKey) ||
            (createdAt != null &&
                conversationMap[conversationKey]!['lastMessageTime'] != null &&
                createdAt.isAfter(conversationMap[conversationKey]!['lastMessageTime']))) {
          conversationMap[conversationKey] = {
            'user1Id': ids[0],
            'user2Id': ids[1],
            'lastMessage': content,
            'lastMessageTime': createdAt,
            'unreadCount': isRead ? 0 : 1,
          };
        } else if (!isRead) {
          // Increment unread count
          conversationMap[conversationKey]!['unreadCount'] = 
              (conversationMap[conversationKey]!['unreadCount'] as int? ?? 0) + 1;
        }
      }

      print('DEBUG unique conversations: ${conversationMap.length}');

      // Collect all unique user IDs
      final Set<String> allUserIds = {};
      for (final data in conversationMap.values) {
        allUserIds.add(data['user1Id'] as String);
        allUserIds.add(data['user2Id'] as String);
      }

      print('DEBUG Fetching ${allUserIds.length} unique user profiles in parallel...');

      // Fetch all user profiles in parallel
      final Map<String, String> userNameCache = {};
      final futures = allUserIds.map((userId) async {
        try {
          final userProfile = await userRepository.fetchUserProfile(userId);
          if (userProfile != null) {
            userNameCache[userId] = userProfile.fullName;
          }
        } catch (e) {
          print('DEBUG Error fetching profile for $userId: $e');
        }
      });

      await Future.wait(futures);
      print('DEBUG Fetched ${userNameCache.length} user profiles');

      // Convert to IndividualChat objects using cached names
      final chats = <IndividualChat>[];

      for (final entry in conversationMap.entries) {
        final data = entry.value;
        final user1Id = data['user1Id'] as String;
        final user2Id = data['user2Id'] as String;

        final chat = IndividualChat(
          id: entry.key,
          user1Id: user1Id,
          user2Id: user2Id,
          user1Name: userNameCache[user1Id],
          user2Name: userNameCache[user2Id],
          lastMessage: data['lastMessage'] as String?,
          lastMessageTime: data['lastMessageTime'] as DateTime?,
          unreadCount: data['unreadCount'] as int? ?? 0,
        );

        chats.add(chat);
      }

      // Sort by latest message time (descending)
      chats.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      print('DEBUG parsed chats: ${chats.length}');
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        chats: chats,
      );
    } catch (e) {
      print('DEBUG fetchAllChats error: $e');
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }
}
