import 'package:flutter/foundation.dart';

/// Represents a user profile in the application.
class Profile {
  /// The unique identifier of the profile (same as the user's ID in Supabase auth).
  final String id;
  
  /// The username of the user.
  final String username;
  
  /// Optional URL to the user's avatar image.
  final String? avatarUrl;
  
  /// When the profile was last updated.
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.updatedAt,
  });

  /// Create a Profile instance from JSON data.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Profile instance to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this Profile with the given fields replaced with new values.
  Profile copyWith({
    String? username,
    String? avatarUrl,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Profile(id: $id, username: $username, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Profile &&
        other.id == id &&
        other.username == username &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ avatarUrl.hashCode;
} 