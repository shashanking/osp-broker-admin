# Chat Feature Implementation Guide for Admin Panel

## Overview
This guide outlines the complete implementation of real-time chat functionality for the admin panel, allowing admins to message users in the app.

## Dependencies Added
```yaml
socket_io_client: ^2.0.3
timeago: ^3.7.1
```

## Architecture

### 1. Domain Layer (`lib/features/chat/domain/`)
- ✅ `chat_message.dart` - Freezed model for chat messages
- ✅ `chat_recipient.dart` - Model for chat inbox recipients
- `chat_user_summary.dart` - Model for user summary info

### 2. Application Layer (`lib/features/chat/application/`)
- `chat_state.dart` - State for individual chat conversations
- `chat_inbox_state.dart` - State for chat inbox/list
- `chat_notifier.dart` - Notifier for chat logic with real-time updates
- `chat_inbox_notifier.dart` - Notifier for inbox/recipients list
- `chat_provider.dart` - Riverpod providers for chat
- `chat_inbox_provider.dart` - Riverpod providers for inbox

### 3. Presentation Layer (`lib/features/chat/presentation/`)
**Pages:**
- `chat_list_screen.dart` - Inbox showing all conversations
- `chat_screen.dart` - Individual chat conversation screen

**Widgets:**
- `chat_bubble.dart` - Message bubble widget
- `typing_indicator.dart` - Animated typing indicator

### 4. Core/Realtime (`lib/core/realtime/`)
- `socket_service.dart` - Socket.IO service for real-time communication

## Key Features

### Real-time Capabilities
- ✅ Socket.IO integration for instant messaging
- ✅ Typing indicators
- ✅ Message delivery status
- ✅ Auto-reconnection
- ✅ User registration on socket

### Chat Features
- Send/receive messages in real-time
- View conversation history
- Mark messages as read
- See typing status
- Optimistic UI updates
- Message timestamps with timeago
- Unread message counts

## API Endpoints Used

```
GET  /chat/recipients              - Get list of chat conversations
GET  /chat/:recipientId            - Get messages with specific user
POST /chat/:recipientId            - Send message to user
POST /chat/updateReadStatus/:id    - Mark messages as read
```

## Socket Events

### Emitted by Client:
- `register` - Register admin user ID
- `typing` - Notify recipient admin is typing
- `stopTyping` - Notify recipient admin stopped typing

### Received by Client:
- `newMessage` - Receive new message
- `typingUpdate` - Receive typing status update

## Implementation Steps

1. ✅ Add dependencies to pubspec.yaml
2. ✅ Create domain models
3. ⏳ Create socket service
4. ⏳ Create state classes
5. ⏳ Create notifiers with real-time logic
6. ⏳ Create UI screens
7. ⏳ Create UI widgets
8. ⏳ Add routes to navigation
9. ⏳ Initialize socket on app start

## Usage for Admin

1. **View Inbox**: Navigate to chat list to see all conversations
2. **Start Chat**: Click on a user to open chat screen
3. **Send Message**: Type and send messages to users
4. **Real-time Updates**: Messages appear instantly via WebSocket
5. **Typing Indicator**: See when users are typing

## Next Steps

Run the following command to generate freezed files:
```bash
cd osp_broker_admin
dart run build_runner build --delete-conflicting-outputs
```

Then implement the remaining files following the structure from `osp_broker/lib/features/chat/`.

## Notes

- Admin can message any user in the system
- All messages are stored in the database
- Socket connection is maintained throughout the app session
- Automatic reconnection on connection loss
- Token-based authentication for socket connection
