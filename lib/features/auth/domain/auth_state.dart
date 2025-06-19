import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

@freezed
class AuthState with _$AuthState {
  const AuthState._();
  
  const factory AuthState.initial() = _AuthStateInitial;
  const factory AuthState.loading() = _AuthStateLoading;
  const factory AuthState.authenticated({
    required String token,
    required Map<String, dynamic> user,
  }) = _AuthStateAuthenticated;
  const factory AuthState.unauthenticated() = _AuthStateUnauthenticated;
  const factory AuthState.error(String message) = _AuthStateError;
  factory AuthState.fromJson(Map<String, dynamic> json) => _$AuthStateFromJson(json);
}

// Login request model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

// User model
class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
 
 User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['_id'] ?? json['id'],
        email: json['email'],
        fullName: json['fullName'],
        role: json['role'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
      };
}

// Extension to add utility methods to AuthState
extension AuthStateX on AuthState {
  // Helper getter to check if user is authenticated
  bool get isAuthenticated => maybeMap(
        authenticated: (_) => true,
        orElse: () => false,
      );
      
  // Helper method to emit state changes
  void emit() {
    // State changes are handled by the notifier
  }
}

// Class to manage auth state stream
class AuthStateStream {
  static final AuthStateStream _instance = AuthStateStream._internal();
  static AuthStateStream get instance => _instance;
  
  final _controller = StreamController<AuthState>.broadcast();
  
  Stream<AuthState> get stream => _controller.stream;
  
  void add(AuthState state) => _controller.add(state);
  
  void dispose() => _controller.close();
  
  factory AuthStateStream() => _instance;
  AuthStateStream._internal();
}
