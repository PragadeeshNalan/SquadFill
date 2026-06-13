import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/data/models/match_model.dart';
import 'package:squadfill/presentation/screens/match_detail_screen.dart';

/// Bottom sheet displaying a summary of a match selected from the map.
class MatchMapBottomSheet extends StatelessWidget {
  final MatchModel match;
  final double distance;

  const MatchMapBottomSheet({
    super.key,
    required this.match,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEE, MMM d • h:mm a').format(match.dateTime);
    final openSlots = match.maxPlayers - match.currentPlayers;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(
                  match.sport == 'Football' ? Icons.sports_soccer : Icons.sports,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      '${match.sport} • $distance km away',
                      style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow(Icons.calendar_today_outlined, formattedDate),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, match.venue),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.people_outline, '$openSlots slots left • ${match.skillLevel}'),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MatchDetailScreen(matchId: match.matchId),
                ),
              );
            },
            child: const Text('View Match Details'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
