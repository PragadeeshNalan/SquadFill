import 'package:cloud_firestore/cloud_firestore.dart';

/// Match data model representing a scheduled game in SquadFill.
/// 
/// Tracks the game title, sport type, location parameters, slot status, 
/// organization details, and whether team balancing mode is enabled.
class MatchModel {
  /// The unique document identifier for the match.
  final String matchId;
  
  /// The title of the match (e.g., "5v5 Friday Football").
  final String title;
  
  /// The sport being played (e.g., Football, Basketball).
  final String sport;
  
  /// Human-readable venue address or location name.
  final String venue;
  
  /// Coordinates for location positioning on Google Maps.
  final double latitude;
  final double longitude;
  
  /// Maximum number of player slots available.
  final int maxPlayers;
  
  /// Current count of players who have joined.
  final int currentPlayers;
  
  /// User UID of the user who organized/created the match.
  final String organizerId;
  
  /// Match status: 'open', 'full', or 'cancelled'.
  final String status;
  
  /// Targeted skill level: Beginner, Intermediate, Advanced.
  final String skillLevel;
  
  /// The date and time when the match is scheduled to be played.
  final DateTime dateTime;
  
  /// The timestamp representing when this match document was created.
  final DateTime createdAt;

  /// Flag indicating whether the team balancing engine is active for slot suggestions.
  final bool balancedMode;

  /// Default constructor for creating a [MatchModel] instance.
  const MatchModel({
    required this.matchId,
    required this.title,
    required this.sport,
    required this.venue,
    required this.latitude,
    required this.longitude,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.organizerId,
    required this.status,
    required this.skillLevel,
    required this.dateTime,
    required this.createdAt,
    this.balancedMode = false,
  });

  /// Factory constructor to construct a [MatchModel] from a Firestore document.
  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MatchModel(
      matchId: doc.id,
      title: data['title'] ?? '',
      sport: data['sport'] ?? 'Football',
      venue: data['venue'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      maxPlayers: data['maxPlayers'] ?? 10,
      currentPlayers: data['currentPlayers'] ?? 0,
      organizerId: data['organizerId'] ?? '',
      status: data['status'] ?? 'open',
      skillLevel: data['skillLevel'] ?? 'Beginner',
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      balancedMode: data['balancedMode'] ?? false,
    );
  }

  /// Converts the [MatchModel] instance into a JSON map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'sport': sport,
      'venue': venue,
      'latitude': latitude,
      'longitude': longitude,
      'maxPlayers': maxPlayers,
      'currentPlayers': currentPlayers,
      'organizerId': organizerId,
      'status': status,
      'skillLevel': skillLevel,
      'dateTime': Timestamp.fromDate(dateTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'balancedMode': balancedMode,
    };
  }

  /// Creates a copy of this [MatchModel] but with the given fields replaced by new values.
  MatchModel copyWith({
    String? matchId,
    String? title,
    String? sport,
    String? venue,
    double? latitude,
    double? longitude,
    int? maxPlayers,
    int? currentPlayers,
    String? organizerId,
    String? status,
    String? skillLevel,
    DateTime? dateTime,
    DateTime? createdAt,
    bool? balancedMode,
  }) {
    return MatchModel(
      matchId: matchId ?? this.matchId,
      title: title ?? this.title,
      sport: sport ?? this.sport,
      venue: venue ?? this.venue,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      organizerId: organizerId ?? this.organizerId,
      status: status ?? this.status,
      skillLevel: skillLevel ?? this.skillLevel,
      dateTime: dateTime ?? this.dateTime,
      createdAt: createdAt ?? this.createdAt,
      balancedMode: balancedMode ?? this.balancedMode,
    );
  }
}
