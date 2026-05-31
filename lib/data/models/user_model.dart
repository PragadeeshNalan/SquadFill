import 'package:cloud_firestore/cloud_firestore.dart';

/// User data model representing a registered player in SquadFill.
/// 
/// Tracks user details, preferences, and reliability scoring statistics.
class UserModel {
  /// The unique identifier of the user (typically matched with Firebase Auth uid).
  final String uid;
  
  /// The display name or nickname of the user.
  final String name;
  
  /// The registered email address of the user.
  final String email;
  
  /// URL pointing to the user's uploaded or pre-selected profile image.
  final String photoUrl;
  
  /// The user's primary/favorite sport (e.g., Football, Basketball).
  final String favoriteSport;
  
  /// The self-assessed skill level of the user (Beginner, Intermediate, Advanced).
  final String skillLevel;
  
  /// User reliability score (calculated range: 0–100, default is 100).
  final double reliabilityScore;
  
  /// Total number of matches the user has joined.
  final int matchesJoined;
  
  /// Number of matches where the user failed to show up without cancelling.
  final int noShowCount;

  /// Default constructor for creating a [UserModel] instance.
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.favoriteSport,
    required this.skillLevel,
    this.reliabilityScore = 100.0,
    this.matchesJoined = 0,
    this.noShowCount = 0,
  });

  /// Factory constructor to construct a [UserModel] from a Firestore document.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      favoriteSport: data['favoriteSport'] ?? 'Football',
      skillLevel: data['skillLevel'] ?? 'Beginner',
      reliabilityScore: (data['reliabilityScore'] ?? 100.0).toDouble(),
      matchesJoined: data['matchesJoined'] ?? 0,
      noShowCount: data['noShowCount'] ?? 0,
    );
  }

  /// Converts the [UserModel] instance into a JSON map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'favoriteSport': favoriteSport,
      'skillLevel': skillLevel,
      'reliabilityScore': reliabilityScore,
      'matchesJoined': matchesJoined,
      'noShowCount': noShowCount,
    };
  }

  /// Creates a copy of this [UserModel] but with the given fields replaced by new values.
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? favoriteSport,
    String? skillLevel,
    double? reliabilityScore,
    int? matchesJoined,
    int? noShowCount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      favoriteSport: favoriteSport ?? this.favoriteSport,
      skillLevel: skillLevel ?? this.skillLevel,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      matchesJoined: matchesJoined ?? this.matchesJoined,
      noShowCount: noShowCount ?? this.noShowCount,
    );
  }
}
