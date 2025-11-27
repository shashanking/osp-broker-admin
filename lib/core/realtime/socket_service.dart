import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:hive_flutter/hive_flutter.dart';

import 'package:osp_broker_admin/core/infrastructure/api_urls.dart';
import 'package:osp_broker_admin/core/infrastructure/providers.dart';

/// Derive Socket base URL from REST base by stripping trailing "/api"
String _deriveSocketBaseUrl() {
  final base = ApiUrls.baseUrl; // e.g. http://host:port/api
  if (base.endsWith('/api')) {
    return base.substring(0, base.length - 4);
  }
  return base;
}

final socketBaseUrlProvider = Provider<String>((ref) => _deriveSocketBaseUrl());

/// Singleton Socket service provider
final socketServiceProvider = Provider<SocketService>((ref) {
  final baseUrl = ref.watch(socketBaseUrlProvider);
  // IMPORTANT: Read the token dynamically each time
  String? dynamicTokenProvider() {
    try {
      // Access the Hive box directly if already open
      if (Hive.isBoxOpen('auth')) {
        final box = Hive.box('auth');
        return box.get('token') as String?;
      }
    } catch (e) {
      debugPrint('[SocketService] Error getting token: $e');
    }
    return null;
  }
  return SocketService(baseUrl: baseUrl, tokenProvider: dynamicTokenProvider);
});

/// Bootstrap provider to ensure a global socket connection
final socketBootstrapProvider = Provider<void>((ref) {
  final socket = ref.watch(socketServiceProvider);
  
  // Watch the authBox async value
  ref.watch(authBoxProvider).whenData((box) {
    final userId = box.get('userId') as String?;
    
    Future.microtask(() async {
      try {
        await socket.connect();
        if (userId != null && userId.isNotEmpty) {
          socket.registerUser(userId);
        }
      } catch (e) {
        debugPrint('[SocketBootstrap] Error: $e');
      }
    });
  });
});

class SocketService {
  final String baseUrl;
  final String? Function() tokenProvider;

  io.Socket? _socket;
  bool _connecting = false;
  String? _lastRegisteredUserId;
  final List<void Function(dynamic)> _newMessageCallbacks = [];
  bool _newMessageListenerRegistered = false;
  final List<void Function(Map<String, dynamic>)> _typingUpdateCallbacks = [];
  bool _typingUpdateListenerRegistered = false;

  SocketService({required this.baseUrl, required this.tokenProvider});

  bool get isConnected => _socket?.connected == true;

  Future<void> connect({Map<String, dynamic>? query}) async {
    if (isConnected || _connecting) return;
    _connecting = true;
    try {
      final token = tokenProvider();
      var builder = io.OptionBuilder()
          .disableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .setTransports(['websocket', 'polling'])
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(999999)
          .setTimeout(20000);
      
      if (token != null) {
        builder = builder.setAuth(<String, dynamic>{'token': token});
      }
      
      final mergedQuery = <String, dynamic>{}
        ..addAll(query ?? const <String, dynamic>{})
        ..addAll(token != null ? <String, dynamic>{'token': token} : const <String, dynamic>{});
      
      builder = builder.setQuery(mergedQuery);
      final opts = builder.build();
      
      debugPrint('[SocketService] Connecting to $baseUrl');
      _socket = io.io(baseUrl, opts);
  
      _socket!.on('connect', (_) {
        debugPrint('[SocketService] ✅ CONNECTED - Socket ID: ${_socket!.id}');
        if (_lastRegisteredUserId != null && _lastRegisteredUserId!.isNotEmpty) {
          _socket!.emit('register', _lastRegisteredUserId);
        }
        
        // Re-register newMessage listener if we have callbacks
        if (_newMessageCallbacks.isNotEmpty && !_newMessageListenerRegistered) {
          void messageHandler(data) {
            debugPrint('[SocketService] 🔔 Message event received: $data');
            debugPrint('[SocketService] Notifying ${_newMessageCallbacks.length} listeners');
            for (final cb in _newMessageCallbacks) {
              try {
                cb(data);
              } catch (e) {
                debugPrint('[SocketService] Error in callback: $e');
              }
            }
          }
          
          _socket!.on('new-message', messageHandler);
          _socket!.on('private-message', messageHandler);
          _socket!.on('message', messageHandler);
          _socket!.on('newMessage', messageHandler);
          _newMessageListenerRegistered = true;
          debugPrint('[SocketService] Message listeners re-registered after reconnect');
        }
        
        // Re-register typingUpdate listener if we have callbacks
        if (_typingUpdateCallbacks.isNotEmpty && !_typingUpdateListenerRegistered) {
          void typingHandler(data) {
            debugPrint('[SocketService] ⌨️ Typing event received: $data');
            debugPrint('[SocketService] Notifying ${_typingUpdateCallbacks.length} typing listeners');
            if (data is Map) {
              final typingData = Map<String, dynamic>.from(data);
              for (final cb in _typingUpdateCallbacks) {
                try {
                  cb(typingData);
                } catch (e) {
                  debugPrint('[SocketService] Error in typing callback: $e');
                }
              }
            }
          }
          
          _socket!.on('user-typing', typingHandler);
          _socket!.on('typingUpdate', typingHandler);
          _typingUpdateListenerRegistered = true;
          debugPrint('[SocketService] Typing listeners re-registered after reconnect');
        }
      });
      
      _socket!.on('connect_error', (err) {
        debugPrint('[SocketService] ❌ CONNECTION ERROR: $err');
      });
      
      _socket!.on('disconnect', (reason) {
        debugPrint('[SocketService] 🔌 DISCONNECTED: $reason');
        _newMessageListenerRegistered = false;
        _typingUpdateListenerRegistered = false;
      });

      _socket!.connect();
      _connecting = false;
    } catch (e) {
      _connecting = false;
      debugPrint('[SocketService] Connection error: $e');
      rethrow;
    }
  }

  void registerUser(String userId) {
    _lastRegisteredUserId = userId;
    if (isConnected) {
      debugPrint('[SocketService] Registering user: $userId');
      _socket!.emit('register', userId);
    }
  }

  void startTyping(String recipientId) {
    if (isConnected) {
      debugPrint('[SocketService] ⌨️ Emitting "typing-start" event for recipient: $recipientId');
      _socket!.emit('typing-start', {'recipientId': recipientId});
    } else {
      debugPrint('[SocketService] ⚠️ Cannot emit typing - socket not connected');
    }
  }

  void stopTyping(String recipientId) {
    if (isConnected) {
      debugPrint('[SocketService] ⌨️ Emitting "typing-stop" event for recipient: $recipientId');
      _socket!.emit('typing-stop', {'recipientId': recipientId});
    } else {
      debugPrint('[SocketService] ⚠️ Cannot emit stopTyping - socket not connected');
    }
  }

  void onNewMessage(void Function(dynamic) callback) {
    debugPrint('[SocketService] 📨 Registering listener for message events');
    debugPrint('[SocketService] Socket is null: ${_socket == null}');
    debugPrint('[SocketService] Socket connected: ${_socket?.connected}');
    
    // Add callback to list if not already present
    if (!_newMessageCallbacks.contains(callback)) {
      _newMessageCallbacks.add(callback);
      debugPrint('[SocketService] Total newMessage listeners: ${_newMessageCallbacks.length}');
    } else {
      debugPrint('[SocketService] Callback already registered, skipping');
    }
    
    // Register the socket listener only once - listen to multiple event names
    if (!_newMessageListenerRegistered && _socket != null) {
      void messageHandler(data) {
        debugPrint('[SocketService] 🔔 Message event received: $data');
        debugPrint('[SocketService] Notifying ${_newMessageCallbacks.length} listeners');
        // Notify all registered callbacks
        for (final cb in _newMessageCallbacks) {
          try {
            cb(data);
          } catch (e) {
            debugPrint('[SocketService] Error in callback: $e');
          }
        }
      }
      
      // Listen to all possible message event names
      _socket!.on('new-message', messageHandler);
      _socket!.on('private-message', messageHandler);
      _socket!.on('message', messageHandler);
      _socket!.on('newMessage', messageHandler); // Keep old name for compatibility
      
      _newMessageListenerRegistered = true;
      debugPrint('[SocketService] ✅ Socket listeners registered for: new-message, private-message, message, newMessage');
    } else if (_socket == null) {
      debugPrint('[SocketService] ⚠️ Socket is null, listener will be registered on connect');
    } else if (_newMessageListenerRegistered) {
      debugPrint('[SocketService] ℹ️ Socket listener already registered');
    }
  }

  void offNewMessage(void Function(dynamic) callback) {
    debugPrint('[SocketService] 🗑️ Removing listener for "newMessage" event');
    _newMessageCallbacks.remove(callback);
    debugPrint('[SocketService] Remaining listeners: ${_newMessageCallbacks.length}');
    
    // If no more callbacks, remove the socket listener
    if (_newMessageCallbacks.isEmpty && _newMessageListenerRegistered) {
      _socket?.off('newMessage');
      _newMessageListenerRegistered = false;
      debugPrint('[SocketService] Socket listener unregistered');
    }
  }

  void onTypingUpdate(void Function(Map<String, dynamic>) callback) {
    debugPrint('[SocketService] ⌨️ Registering listener for typing events');
    debugPrint('[SocketService] Socket is null: ${_socket == null}');
    debugPrint('[SocketService] Socket connected: ${_socket?.connected}');
    
    // Add callback to list if not already present
    if (!_typingUpdateCallbacks.contains(callback)) {
      _typingUpdateCallbacks.add(callback);
      debugPrint('[SocketService] Total typingUpdate listeners: ${_typingUpdateCallbacks.length}');
    } else {
      debugPrint('[SocketService] Typing callback already registered, skipping');
    }
    
    // Register the socket listener only once
    if (!_typingUpdateListenerRegistered && _socket != null) {
      void typingHandler(data) {
        debugPrint('[SocketService] ⌨️ Typing event received: $data');
        debugPrint('[SocketService] Notifying ${_typingUpdateCallbacks.length} typing listeners');
        if (data is Map) {
          final typingData = Map<String, dynamic>.from(data);
          for (final cb in _typingUpdateCallbacks) {
            try {
              cb(typingData);
            } catch (e) {
              debugPrint('[SocketService] Error in typing callback: $e');
            }
          }
        }
      }
      
      // Listen to all possible typing event names
      _socket!.on('user-typing', typingHandler);
      _socket!.on('typingUpdate', typingHandler); // Keep old name for compatibility
      
      _typingUpdateListenerRegistered = true;
      debugPrint('[SocketService] ✅ Typing listeners registered for: user-typing, typingUpdate');
    } else if (_socket == null) {
      debugPrint('[SocketService] ⚠️ Socket is null, typing listener will be registered on connect');
    } else if (_typingUpdateListenerRegistered) {
      debugPrint('[SocketService] ℹ️ typingUpdate listener already registered');
    }
  }

  void offTypingUpdate(void Function(Map<String, dynamic>) callback) {
    debugPrint('[SocketService] 🗑️ Removing listener for "typingUpdate" event');
    _typingUpdateCallbacks.remove(callback);
    debugPrint('[SocketService] Remaining typing listeners: ${_typingUpdateCallbacks.length}');
    
    // If no more callbacks, remove the socket listener
    if (_typingUpdateCallbacks.isEmpty && _typingUpdateListenerRegistered) {
      _socket?.off('typingUpdate');
      _typingUpdateListenerRegistered = false;
      debugPrint('[SocketService] typingUpdate socket listener unregistered');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
