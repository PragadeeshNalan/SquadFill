import 'package:flutter/material.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/data/models/match_model.dart';
import 'package:squadfill/presentation/widgets/match_map_bottom_sheet.dart';

/// Horizontally scrollable list of nearby matches shown below the map.
class NearbyMatchCardStrip extends StatelessWidget {
  final List<MatchModel> matches;
  final Map<String, double> distances;

  const NearbyMatchCardStrip({
    super.key,
    required this.matches,
    required this.distances,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          final distance = distances[match.matchId] ?? 0.0;
          final openSlots = match.maxPlayers - match.currentPlayers;

          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => MatchMapBottomSheet(
                  match: match,
                  distance: distance,
                ),
              );
            },
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        match.sport == 'Football' ? Icons.sports_soccer : Icons.sports,
                        color: AppTheme.secondaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$distance km away',
                    style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$openSlots SLOTS',
                        style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          match.skillLevel.toUpperCase(),
                          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
