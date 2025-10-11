import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';

/// Extension to convert Firebase User to UserEntity
extension UserModelExtension on User {
  UserEntity toEntity() {
    return UserEntity(
      id: uid,
      email: email ?? '',
      displayName: displayName,
      photoUrl: photoURL,
      isEmailVerified: emailVerified,
      createdAt: metadata.creationTime,
    );
  }
}

/// User model for data layer
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    required super.isEmailVerified,
    super.createdAt,
  });

  /// Create UserModel from Firebase User
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
    );
  }

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Convert to UserEntity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
    );
  }
}
