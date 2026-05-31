import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squadfill/data/models/match_model.dart';
import 'package:squadfill/data/models/participant_model.dart';
import 'package:squadfill/data/models/user_model.dart';
import 'package:squadfill/data/repositories/match_repository_impl.dart';
import 'package:squadfill/domain/repositories/match_repository.dart';
import 'package:squadfill/presentation/providers/auth_providers.dart';

/// Provider exposing the [MatchRepository] implementation.
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepositoryImpl();
});

/// StateProvider holding the active search bar filter string.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// StateProvider holding the active sport filter category (e.g., 'All', 'Football').
final sportFilterProvider = StateProvider<String>((ref) => 'All');

/// StreamProvider listening to the active filtered matches list.
final activeMatchesStreamProvider = StreamProvider<List<MatchModel>>((ref) {
  final matchRepo = ref.watch(matchRepositoryProvider);
  final sport = ref.watch(sportFilterProvider);
  final query = ref.watch(searchQueryProvider);
  
  return matchRepo.getActiveMatchesStream(
    sportFilter: sport == 'All' ? null : sport,
    query: query,
  );
});

/// StreamProvider listening to matches joined by the currently authenticated user.
final joinedMatchesStreamProvider = StreamProvider<List<MatchModel>>((ref) {
  final matchRepo = ref.watch(matchRepositoryProvider);
  final currentUser = ref.watch(currentSquadUserProvider);
  
  if (currentUser == null) return Stream.value([]);
  return matchRepo.getJoinedMatchesStream(currentUser.uid);
});

/// Family StreamProvider listening to a specific match document's details.
final matchDetailStreamProvider = StreamProvider.family<MatchModel?, String>((ref, matchId) {
  final matchRepo = ref.watch(matchRepositoryProvider);
  return matchRepo.getMatchDetailStream(matchId);
});

/// Family StreamProvider listening to participants joined in a specific match.
final matchParticipantsStreamProvider = StreamProvider.family<List<ParticipantModel>, String>((ref, matchId) {
  final matchRepo = ref.watch(matchRepositoryProvider);
  return matchRepo.getMatchParticipantsStream(matchId);
});

/// Family FutureProvider retrieving the profile model of another user (e.g., organizer).
final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, userId) {
  final matchRepo = ref.watch(matchRepositoryProvider);
  return matchRepo.getUserProfile(userId);
});

/// StateNotifier to manage match actions (creation, joining, leaving)
/// and track asynchronous operation states.
class MatchController extends StateNotifier<AsyncValue<void>> {
  final MatchRepository _matchRepository;

  /// Constructor initializing with standard empty state and injected repository.
  MatchController(this._matchRepository) : super(const AsyncData(null));

  /// Host a new match.
  /// 
  /// Returns the matchId on success, null on failure.
  Future<String?> hostMatch(MatchModel match) async {
    state = const AsyncLoading();
    try {
      final matchId = await _matchRepository.createMatch(match);
      state = const AsyncData(null);
      return matchId;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }

  /// Join an open match slot.
  Future<bool> joinMatchSlot(String matchId, String userId) async {
    state = const AsyncLoading();
    try {
      await _matchRepository.joinMatch(matchId, userId);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  /// Leave/Cancel participation in a match.
  Future<bool> leaveMatchSlot(String matchId, String userId) async {
    state = const AsyncLoading();
    try {
      await _matchRepository.leaveMatch(matchId, userId);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

/// Provider exposing the [MatchController] state and actions.
final matchControllerProvider = StateNotifierProvider<MatchController, AsyncValue<void>>((ref) {
  final matchRepo = ref.watch(matchRepositoryProvider);
  return MatchController(matchRepo);
});
