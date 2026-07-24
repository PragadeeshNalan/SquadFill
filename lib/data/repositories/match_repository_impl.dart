import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:squadfill/data/models/match_model.dart';
import 'package:squadfill/data/models/participant_model.dart';
import 'package:squadfill/data/models/user_model.dart';
import 'package:squadfill/domain/repositories/match_repository.dart';
import 'package:squadfill/core/constants/app_constants.dart';

/// Data Repository implementation for [MatchRepository] utilizing Firestore.
class MatchRepositoryImpl implements MatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<MatchModel>> getActiveMatchesStream({String? sportFilter, String? query}) {
    return _firestore.collection(AppConstants.matchesCollection)
        .where('status', isNotEqualTo: 'cancelled')
        .snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MatchModel.fromFirestore(doc))
          .where((m) => m.dateTime.isAfter(DateTime.now())) // AUTO EXPIRE
          .where((m) => sportFilter == null || m.sport == sportFilter) // DYNAMIC FILTER
          .toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  @override
  Stream<MatchModel?> getMatchDetailStream(String matchId) {
    return _firestore
        .collection(AppConstants.matchesCollection)
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.exists ? MatchModel.fromFirestore(doc) : null);
  }

  @override
  Stream<List<ParticipantModel>> getMatchParticipantsStream(String matchId) {
    return _firestore
        .collection(AppConstants.participantsCollection)
        .where('matchId', isEqualTo: matchId)
        .snapshots()
        .map((snapshot) {
          // Filter out participants who have cancelled their attendance
          return snapshot.docs
              .map((doc) => ParticipantModel.fromFirestore(doc))
              .where((p) => p.cancelledAt == null)
              .toList();
        });
  }

  @override
  Future<String> createMatch(MatchModel match) async {
    try {
      final docRef = _firestore.collection(AppConstants.matchesCollection).doc();
      final String matchId = docRef.id;

      // Prepare match document
      final matchToSave = match.copyWith(
        matchId: matchId,
        currentPlayers: 1, // Automatically includes the organizer
      );

      // Create a batch write to save match and add organizer as participant
      final batch = _firestore.batch();
      
      batch.set(docRef, matchToSave.toFirestore());

      // Organizer participant doc
      final participantRef = _firestore
          .collection(AppConstants.participantsCollection)
          .doc('${matchId}_${match.organizerId}');
      
      final participant = ParticipantModel(
        id: '${matchId}_${match.organizerId}',
        matchId: matchId,
        userId: match.organizerId,
        joinedAt: DateTime.now(),
      );

      batch.set(participantRef, participant.toFirestore());

      // Increment matchesJoined count in organizer profile
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(match.organizerId);
      
      batch.update(userRef, {
        'matchesJoined': FieldValue.increment(1),
      });

      await batch.commit();
      return matchId;
    } catch (e) {
      throw Exception('Failed to create match: ${e.toString()}');
    }
  }

  @override
  Future<void> joinMatch(String matchId, String userId) async {
    try {
      final matchRef = _firestore.collection(AppConstants.matchesCollection).doc(matchId);
      final participantRef = _firestore
          .collection(AppConstants.participantsCollection)
          .doc('${matchId}_$userId');
      final userRef = _firestore.collection(AppConstants.usersCollection).doc(userId);

      // Run transactional operations to prevent race conditions
      await _firestore.runTransaction((transaction) async {
        final matchSnapshot = await transaction.get(matchRef);
        
        if (!matchSnapshot.exists) {
          throw Exception('Match document does not exist.');
        }

        final match = MatchModel.fromFirestore(matchSnapshot);

        if (match.currentPlayers >= match.maxPlayers) {
          throw Exception('Game is already full!');
        }

        if (match.status == 'cancelled') {
          throw Exception('This match has been cancelled by the organizer.');
        }

        final participantSnapshot = await transaction.get(participantRef);
        
        if (participantSnapshot.exists) {
          final participant = ParticipantModel.fromFirestore(participantSnapshot);
          if (participant.cancelledAt == null) {
            throw Exception('You are already registered for this match.');
          }
        }

        // 1. Create or restore participant document
        final newParticipant = ParticipantModel(
          id: '${matchId}_$userId',
          matchId: matchId,
          userId: userId,
          joinedAt: DateTime.now(),
        );

        transaction.set(participantRef, newParticipant.toFirestore());

        // 2. Increment active players count
        final int updatedPlayersCount = match.currentPlayers + 1;
        final String updatedStatus = updatedPlayersCount == match.maxPlayers ? 'full' : 'open';

        transaction.update(matchRef, {
          'currentPlayers': updatedPlayersCount,
          'status': updatedStatus,
        });

        // 3. Update User Profile Matches count
        transaction.update(userRef, {
          'matchesJoined': FieldValue.increment(1),
        });
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> leaveMatch(String matchId, String userId) async {
    try {
      final matchRef = _firestore.collection(AppConstants.matchesCollection).doc(matchId);
      final participantRef = _firestore
          .collection(AppConstants.participantsCollection)
          .doc('${matchId}_$userId');
      final userRef = _firestore.collection(AppConstants.usersCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final matchSnapshot = await transaction.get(matchRef);
        
        if (!matchSnapshot.exists) {
          throw Exception('Match does not exist.');
        }

        final match = MatchModel.fromFirestore(matchSnapshot);
        final participantSnapshot = await transaction.get(participantRef);

        if (!participantSnapshot.exists) {
          throw Exception('You are not registered in this match.');
        }

        final participant = ParticipantModel.fromFirestore(participantSnapshot);
        if (participant.cancelledAt != null) {
          throw Exception('You have already left this match.');
        }

        // 1. Mark participant as cancelled (we keep it for late cancel history tracking)
        // Late cancellations occur if within 2 hours of play
        final bool isLateCancel = match.dateTime.difference(DateTime.now()).inHours < 2;

        transaction.update(participantRef, {
          'cancelledAt': Timestamp.fromDate(DateTime.now()),
        });

        // 2. Decrement active players count
        final int updatedPlayersCount = match.currentPlayers - 1;
        transaction.update(matchRef, {
          'currentPlayers': updatedPlayersCount,
          'status': 'open', // Auto-returns to open
        });

        // 3. Decrement user joined matches count
        // If late cancellation, we also flag the profile for reliability deductions
        final updates = <String, dynamic>{
          'matchesJoined': FieldValue.increment(-1),
        };
        
        if (isLateCancel) {
          // Track reliability deduction hooks here (calculated post-game or on-action)
          // We can optionally decrement here or let our scoring engine handle it.
          // Let's decrement reliabilityScore directly by 5 for late cancellations!
          final userSnapshot = await transaction.get(userRef);
          if (userSnapshot.exists) {
            final double currentScore = (userSnapshot.data()?['reliabilityScore'] ?? 100.0).toDouble();
            final double newScore = (currentScore - 5.0).clamp(0.0, 100.0);
            updates['reliabilityScore'] = newScore;
          }
        }

        transaction.update(userRef, updates);
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(userId).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  @override
  Stream<List<MatchModel>> getJoinedMatchesStream(String userId) {
    // Queries participants collection for user records
    return _firestore
        .collection(AppConstants.participantsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final activeJoined = snapshot.docs
              .map((doc) => ParticipantModel.fromFirestore(doc))
              .where((p) => p.cancelledAt == null)
              .toList();

          if (activeJoined.isEmpty) return [];

          // Fetch match detail structures for all active joined matches
          final List<MatchModel> matches = [];
          for (final p in activeJoined) {
            final matchDoc = await _firestore.collection(AppConstants.matchesCollection).doc(p.matchId).get();
            if (matchDoc.exists) {
              matches.add(MatchModel.fromFirestore(matchDoc));
            }
          }

          // Sort matches chronologically
          matches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return matches;
        });
  }

  @override
  Stream<List<MatchModel>> getNearbyMatchesStream() {
    return _firestore
        .collection(AppConstants.matchesCollection)
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MatchModel.fromFirestore(doc))
          .where((m) => m.latitude != 0.0 && m.longitude != 0.0)
          .toList();
    });
  }
}
