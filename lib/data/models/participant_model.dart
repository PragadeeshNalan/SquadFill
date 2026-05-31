import 'package:cloud_firestore/cloud_firestore.dart';

/// Participant data model representing a user's join record for a match.
/// 
/// Tracks joining timestamp, attendance status, and late cancellations.
class ParticipantModel {
  /// Compound identifier usually formatted as "matchId_userId".
  final String id;
  
  /// The ID of the match joined.
  final String matchId;
  
  /// The UID of the participating user.
  final String userId;
  
  /// The date and time when the user joined the match.
  final DateTime joinedAt;
  
  /// Tracks if the user attended the game (null means game hasn't happened yet).
  final bool? attended;
  
  /// Timestamp if the user cancelled their spot, null if active participant.
  final DateTime? cancelledAt;

  /// Default constructor for creating a [ParticipantModel] instance.
  const ParticipantModel({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.joinedAt,
    this.attended,
    this.cancelledAt,
  });

  /// Factory constructor to construct a [ParticipantModel] from a Firestore document.
  factory ParticipantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ParticipantModel(
      id: doc.id,
      matchId: data['matchId'] ?? '',
      userId: data['userId'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attended: data['attended'] as bool?,
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [ParticipantModel] instance into a JSON map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'userId': userId,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'attended': attended,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }

  /// Creates a copy of this [ParticipantModel] but with the given fields replaced by new values.
  ParticipantModel copyWith({
    String? id,
    String? matchId,
    String? userId,
    DateTime? joinedAt,
    bool? attended,
    DateTime? cancelledAt,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
      attended: attended ?? this.attended,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}
