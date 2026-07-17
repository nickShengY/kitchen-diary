import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final String avatarEmoji;
  final bool isVip;
  final DateTime? vipExpiresAt;
  final List<String> followers;
  final List<String> following;
  final List<String> favoriteRecipes;
  final List<String> savedRecipes;
  final int recipesCount;
  final int likesReceived;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, dynamic>? preferences;
  final List<String> badges;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.bio,
    this.avatarEmoji = '👨‍🍳',
    this.isVip = false,
    this.vipExpiresAt,
    this.followers = const [],
    this.following = const [],
    this.favoriteRecipes = const [],
    this.savedRecipes = const [],
    this.recipesCount = 0,
    this.likesReceived = 0,
    required this.createdAt,
    required this.lastActiveAt,
    this.preferences,
    this.badges = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Chef',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      avatarEmoji: data['avatarEmoji'] ?? '👨‍🍳',
      isVip: data['isVip'] ?? false,
      vipExpiresAt: data['vipExpiresAt'] != null
          ? (data['vipExpiresAt'] as Timestamp).toDate()
          : null,
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      favoriteRecipes: List<String>.from(data['favoriteRecipes'] ?? []),
      savedRecipes: List<String>.from(data['savedRecipes'] ?? []),
      recipesCount: data['recipesCount'] ?? 0,
      likesReceived: data['likesReceived'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp).toDate(),
      preferences: data['preferences'],
      badges: List<String>.from(data['badges'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'avatarEmoji': avatarEmoji,
      'isVip': isVip,
      'vipExpiresAt':
          vipExpiresAt != null ? Timestamp.fromDate(vipExpiresAt!) : null,
      'followers': followers,
      'following': following,
      'favoriteRecipes': favoriteRecipes,
      'savedRecipes': savedRecipes,
      'recipesCount': recipesCount,
      'likesReceived': likesReceived,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'preferences': preferences,
      'badges': badges,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? avatarEmoji,
    bool? isVip,
    DateTime? vipExpiresAt,
    List<String>? followers,
    List<String>? following,
    List<String>? favoriteRecipes,
    List<String>? savedRecipes,
    int? recipesCount,
    int? likesReceived,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? preferences,
    List<String>? badges,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      isVip: isVip ?? this.isVip,
      vipExpiresAt: vipExpiresAt ?? this.vipExpiresAt,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      favoriteRecipes: favoriteRecipes ?? this.favoriteRecipes,
      savedRecipes: savedRecipes ?? this.savedRecipes,
      recipesCount: recipesCount ?? this.recipesCount,
      likesReceived: likesReceived ?? this.likesReceived,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
      badges: badges ?? this.badges,
    );
  }

  bool get hasValidVip =>
      isVip && vipExpiresAt != null && vipExpiresAt!.isAfter(DateTime.now());
}
