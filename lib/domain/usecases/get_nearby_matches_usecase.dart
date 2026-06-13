import 'package:squadfill/data/models/match_model.dart';
import 'package:squadfill/domain/repositories/match_repository.dart';
import 'package:squadfill/core/utils/distance_utils.dart';

/// Usecase to retrieve matches sorted by distance from the user.
class GetNearbyMatchesUseCase {
  final MatchRepository _repository;

  GetNearbyMatchesUseCase(this._repository);

  Stream<List<MatchModel>> call(double userLat, double userLng) {
    return _repository.getNearbyMatchesStream().map((matches) {
      // Calculate distances client-side for dynamic sorting
      final List<MatchModelWithDistance> matchedWithDist = matches.map((m) {
        final distance = DistanceUtils.calculateDistanceKm(
          userLat, userLng, m.latitude, m.longitude
        );
        return MatchModelWithDistance(m, distance);
      }).toList();

      // Sort by distance ascending
      matchedWithDist.sort((a, b) => a.distance.compareTo(b.distance));

      return matchedWithDist.map((mw) => mw.match).toList();
    });
  }
}

/// Helper class to hold match model along with its calculated distance.
class MatchModelWithDistance {
  final MatchModel match;
  final double distance;

  MatchModelWithDistance(this.match, this.distance);
}
