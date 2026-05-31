import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification data model representing an in-app alert for a user.
/// 
/// Used to keep players informed about upcoming match status updates,
/// reminders, and slot confirmations.
class NotificationModel {
  /// Unique document ID for the notification.
  final String id;
  
  /// The UID of the target user receiving this notification.
  final String userId;
  
  /// Type of notification (e.g., 'reminder', 'match_cancelled', 'slot_filled', 'match_confirmed').
  final String type;
  
  /// The body message of the notification.
  final String message;
  
  /// Optional associated Match ID for routing or context.
  final String? matchId;
  
  /// Flag indicating whether the user has read this notification.
  final bool read;
  
  /// Timestamp indicating when this notification was generated.
  final DateTime createdAt;

  /// Default constructor for creating a [NotificationModel] instance.
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.matchId,
    required this.read,
    required this.createdAt,
  });

  /// Factory constructor to construct a [NotificationModel] from a Firestore document.
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'info',
      message: data['message'] ?? '',
      matchId: data['matchId'],
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts the [NotificationModel] instance into a JSON map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'message': message,
      'matchId': matchId,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy of this [NotificationModel] but with the given fields replaced by new values.
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? message,
    String? matchId,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      matchId: matchId ?? this.matchId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
