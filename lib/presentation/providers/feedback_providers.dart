import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squadfill/data/models/match_model.dart';
import 'package:squadfill/data/models/skill_feedback_model.dart';
import 'package:squadfill/data/repositories/feedback_repository_impl.dart';
import 'package:squadfill/domain/usecases/submit_skill_feedback_usecase.dart';
import 'package:squadfill/presentation/providers/auth_providers.dart';
import 'package:squadfill/presentation/providers/match_providers.dart';

/// Provider exposing the [FeedbackRepository].
final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository();
});

/// Provider for the [SubmitSkillFeedbackUseCase].
final submitSkillFeedbackUseCaseProvider = Provider<SubmitSkillFeedbackUseCase>((ref) {
  final repo = ref.watch(feedbackRepositoryProvider);
  return SubmitSkillFeedbackUseCase(repo);
});

/// StreamProvider for match IDs pending feedback from the current user.
final pendingFeedbackMatchIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentSquadUserProvider);
  if (user == null) return Stream.value([]);
  
  final repo = ref.watch(feedbackRepositoryProvider);
  return repo.getPendingFeedbackMatchIds(user.uid);
});

/// StreamProvider for full [MatchModel] objects pending feedback.
final pendingFeedbackMatchesProvider = StreamProvider<List<MatchModel>>((ref) {
  final pendingIdsAsync = ref.watch(pendingFeedbackMatchIdsProvider);
  
  return pendingIdsAsync.when(
    data: (ids) async* {
      if (ids.isEmpty) {
        yield [];
        return;
      }

      final List<MatchModel> pendingMatches = [];
      for (final id in ids) {
        // Only include matches that have already happened
        final match = await ref.read(matchRepositoryProvider).getMatchDetailStream(id).first;
        if (match != null && match.dateTime.isBefore(DateTime.now())) {
          pendingMatches.add(match);
        }
      }
      yield pendingMatches;
    },
    loading: () => Stream.value([]),
    error: (e, s) => Stream.value([]),
  );
});

/// StateNotifier to manage skill feedback submission state.
class FeedbackController extends StateNotifier<AsyncValue<void>> {
  final SubmitSkillFeedbackUseCase _submitUseCase;

  FeedbackController(this._submitUseCase) : super(const AsyncData(null));

  Future<bool> submitFeedback(SkillFeedbackModel feedback) async {
    state = const AsyncLoading();
    try {
      await _submitUseCase(feedback);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

/// Provider exposing [FeedbackController].
final feedbackControllerProvider = StateNotifierProvider<FeedbackController, AsyncValue<void>>((ref) {
  final useCase = ref.watch(submitSkillFeedbackUseCaseProvider);
  return FeedbackController(useCase);
});
