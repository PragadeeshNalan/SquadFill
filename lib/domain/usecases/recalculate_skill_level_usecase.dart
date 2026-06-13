import 'package:squadfill/data/repositories/feedback_repository_impl.dart';

/// Usecase to trigger recalculation of a user's skill level.
class RecalculateSkillLevelUseCase {
  final FeedbackRepository _repository;

  RecalculateSkillLevelUseCase(this._repository);

  Future<void> call(String userId) async {
    await _repository.recalculateSkillLevel(userId);
  }
}
