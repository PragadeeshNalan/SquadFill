import 'package:cloud_firestore/cloud_firestore.dart';

/// Skill Feedback data model representing a rating given by one player to another.
class SkillFeedbackModel {
  /// The unique identifier for the feedback record.
  final String feedbackId;
  
  /// The UID of the user giving the feedback.
  final String fromUserId;
  
  /// The UID of the user receiving the feedback.
  final String toUserId;
  
  /// The ID of the match where they played together.
  final String matchId;
  
  /// The rating given (Beginner, Intermediate, or Advanced).
  final String ratingGiven;
  
  /// The timestamp when the feedback was submitted.
  final DateTime createdAt;

  /// Default constructor for creating a [SkillFeedbackModel] instance.
  const SkillFeedbackModel({
    required this.feedbackId,
    required this.fromUserId,
    required this.toUserId,
    required this.matchId,
    required this.ratingGiven,
    required this.createdAt,
  });

  /// Factory constructor to construct a [SkillFeedbackModel] from a Firestore document.
  factory SkillFeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SkillFeedbackModel(
      feedbackId: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      matchId: data['matchId'] ?? '',
      ratingGiven: data['ratingGiven'] ?? 'Beginner',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts the [SkillFeedbackModel] instance into a JSON map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'matchId': matchId,
      'ratingGiven': ratingGiven,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
