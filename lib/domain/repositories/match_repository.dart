import 'package:squadfill/data/models/match_model.dart';
import 'package:squadfill/data/models/participant_model.dart';
import 'package:squadfill/data/models/user_model.dart';

/// Domain interface defining database contracts for Match operations.
/// 
/// Decouples the UI widgets from active Firebase database listeners.
abstract class MatchRepository {
  /// Stream to listen to active matches, optionally filtered by sport and search title.
  Stream<List<MatchModel>> getActiveMatchesStream({String? sportFilter, String? query});

  /// Stream to listen to real-time updates for a single match document.
  Stream<MatchModel?> getMatchDetailStream(String matchId);

  /// Stream to listen to the list of participants joined in a match.
  Stream<List<ParticipantModel>> getMatchParticipantsStream(String matchId);

  /// Creates a new match document in Firestore.
  /// 
  /// Returns the newly generated match ID.
  Future<String> createMatch(MatchModel match);

  /// Join a match by creating a Participant record and incrementing players count in a transaction.
  Future<void> joinMatch(String matchId, String userId);

  /// Leave a match by removing the Participant record and decrementing players count in a transaction.
  Future<void> leaveMatch(String matchId, String userId);

  /// Retrieve a specific user's profile info (e.g. for organizer details).
  Future<UserModel?> getUserProfile(String userId);

  /// Stream of matches that the user has joined (for Dashboard/Stats).
  Stream<List<MatchModel>> getJoinedMatchesStream(String userId);

  /// Stream of open matches with location coordinates set.
  Stream<List<MatchModel>> getNearbyMatchesStream();
}
