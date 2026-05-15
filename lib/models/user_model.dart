// lib/models/user_model.dart

/// Application user model mirroring Firestore document.
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final int totalScans;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.totalScans = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      totalScans: json['total_scans'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'display_name': displayName,
    'photo_url': photoUrl,
    'created_at': createdAt.toIso8601String(),
    'total_scans': totalScans,
  };

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    int? totalScans,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      totalScans: totalScans ?? this.totalScans,
    );
  }

  @override
  String toString() => 'UserModel(uid: $uid, email: $email)';
}
