import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:squadfill/presentation/providers/match_providers.dart';
import 'package:squadfill/presentation/screens/match_detail_screen.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/core/constants/app_constants.dart';
import 'package:squadfill/data/models/match_model.dart';

/// Screen exhibiting real-time list of matches with search and category filters.
class MatchListScreen extends ConsumerWidget {
  /// Default constructor for [MatchListScreen].
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(activeMatchesStreamProvider);
    final selectedSport = ref.watch(sportFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar & Header
            _buildSearchHeader(context, ref, searchQuery),

            // 2. Horizontal Sports filter badges
            _buildCategorySelector(ref, selectedSport),
            const SizedBox(height: 16),

            // 3. Real-time Match List
            Expanded(
              child: matchesAsync.when(
                data: (matches) {
                  if (matches.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return _buildMatchCard(context, match);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
                error: (err, stack) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading matches: ${err.toString()}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Search header component
  Widget _buildSearchHeader(BuildContext context, WidgetRef ref, String query) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FIND MATCHES',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 16),
          // Search Input text field
          TextField(
            onChanged: (val) {
              ref.read(searchQueryProvider.notifier).state = val;
            },
            decoration: InputDecoration(
              hintText: 'Search by match name or venue...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryColor),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.textSecondaryColor),
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Category filter badges list
  Widget _buildCategorySelector(WidgetRef ref, String selectedSport) {
    // Add "All" option to categories
    final List<String> categories = ['All', ...AppConstants.sports];

    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final sport = categories[index];
          final isSelected = selectedSport == sport;
          
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: FilterChip(
              label: Text(sport),
              selected: isSelected,
              onSelected: (bool selected) {
                ref.read(sportFilterProvider.notifier).state = sport;
              },
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Match Feed Card Builder
  Widget _buildMatchCard(BuildContext context, MatchModel match) {
    final formattedDate = DateFormat('EEEE, MMMM d • h:mm a').format(match.dateTime);
    final openSlots = match.maxPlayers - match.currentPlayers;
    final isFull = openSlots <= 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MatchDetailScreen(matchId: match.matchId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sport + Title + Badge Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.secondaryColor.withOpacity(0.08),
                    child: Icon(
                      match.sport == 'Football' ? Icons.sports_soccer : Icons.sports,
                      color: AppTheme.secondaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          match.sport,
                          style: const TextStyle(
                            color: AppTheme.secondaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Open/Full status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isFull 
                          ? Colors.white.withOpacity(0.06) 
                          : AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFull ? 'FULL' : 'OPEN',
                      style: TextStyle(
                        color: isFull ? Colors.grey : AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date Row
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 10),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Venue location Row
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      match.venue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Bottom Slots count & Skill level Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        isFull 
                            ? 'All slots filled' 
                            : '$openSlots of ${match.maxPlayers} slots open',
                        style: TextStyle(
                          fontSize: 12,
                          color: isFull ? Colors.grey : AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  // Skill label tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      match.skillLevel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds empty state illustration when list has no items matching filters.
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No matches found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t find any active matches matching your search filters. Try clearing your search string or toggling different sports.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
