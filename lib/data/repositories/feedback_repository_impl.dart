import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:squadfill/core/constants/app_constants.dart';
import 'package:squadfill/data/models/skill_feedback_model.dart';
import 'package:squadfill/data/models/user_model.dart';

/// Repository for handling teammate skill feedback operations.
class FeedbackRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submits feedback for a teammate and marks the participant record as rated.
  Future<void> submitFeedback(SkillFeedbackModel feedback) async {
    final batch = _firestore.batch();

    // 1. Create feedback record
    final feedbackRef = _firestore.collection(AppConstants.skillFeedbackCollection).doc();
    batch.set(feedbackRef, feedback.toFirestore());

    // 2. Mark match as rated in participants collection
    final participantRef = _firestore
        .collection(AppConstants.participantsCollection)
        .doc('${feedback.matchId}_${feedback.fromUserId}');
    
    batch.update(participantRef, {'feedbackGiven': true});

    await batch.commit();

    // 3. Trigger skill level recalculation for the recipient
    await recalculateSkillLevel(feedback.toUserId);
  }

  /// Retrieves all feedback records received by a specific user.
  Future<List<SkillFeedbackModel>> getFeedbackForUser(String toUserId) async {
    final snapshot = await _firestore
        .collection(AppConstants.skillFeedbackCollection)
        .where('toUserId', isEqualTo: toUserId)
        .get();

    return snapshot.docs.map((doc) => SkillFeedbackModel.fromFirestore(doc)).toList();
  }

  /// Recalculates the skill level of a user based on all received ratings.
  Future<void> recalculateSkillLevel(String userId) async {
    final feedbackList = await getFeedbackForUser(userId);
    if (feedbackList.isEmpty) return;

    double totalScore = 0;
    for (final feedback in feedbackList) {
      totalScore += AppConstants.skillLevelToInt(feedback.ratingGiven);
    }

    final double avgScore = totalScore / feedbackList.length;
    final int roundedScore = avgScore.round();
    final String newSkillLevel = AppConstants.skillLevelFromInt(roundedScore);

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'skillLevel': newSkillLevel});
  }

  /// Returns a stream of matches where the user participated but hasn't given feedback yet.
  Stream<List<String>> getPendingFeedbackMatchIds(String userId) {
    return _firestore
        .collection(AppConstants.participantsCollection)
        .where('userId', isEqualTo: userId)
        .where('feedbackGiven', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.get('matchId') as String).toList();
        });
  }
}
