import 'package:squadfill/data/models/skill_feedback_model.dart';
import 'package:squadfill/data/repositories/feedback_repository_impl.dart';

/// Usecase to handle submission of teammate skill feedback.
class SubmitSkillFeedbackUseCase {
  final FeedbackRepository _repository;

  SubmitSkillFeedbackUseCase(this._repository);

  Future<void> call(SkillFeedbackModel feedback) async {
    await _repository.submitFeedback(feedback);
  }
}
