import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:squadfill/presentation/providers/auth_providers.dart';
import 'package:squadfill/presentation/providers/match_providers.dart';
import 'package:squadfill/presentation/screens/match_detail_screen.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/core/constants/app_constants.dart';
import 'package:squadfill/data/models/match_model.dart';

/// Form screen allowing authenticated users to schedule and host a new match.
class CreateMatchScreen extends ConsumerStatefulWidget {
  /// Default constructor for [CreateMatchScreen].
  const CreateMatchScreen({super.key});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _maxPlayersController = TextEditingController(text: '10');

  String _selectedSport = AppConstants.sports.first;
  String _selectedSkill = AppConstants.skillLevels.first;
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  
  bool _balancedMode = false;

  // Chennai coordinates as standard defaults
  double _latitude = 13.0827;
  double _longitude = 80.2707;

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _maxPlayersController.dispose();
    super.dispose();
  }

  /// Opens standard Android/iOS Date Picker overlay.
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Opens Time Picker overlay.
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// Submits the match data.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentSquadUserProvider);
    if (user == null) return;

    // Combine date and time parameters
    final DateTime matchDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (matchDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Matches must be scheduled in the future!'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final int maxPlayers = int.tryParse(_maxPlayersController.text) ?? 10;

    // Create MatchModel instance
    final newMatch = MatchModel(
      matchId: '', // Auto-generated in repo transaction
      title: _titleController.text.trim(),
      sport: _selectedSport,
      venue: _venueController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      maxPlayers: maxPlayers,
      currentPlayers: 1, // Organizer automatically joins
      organizerId: user.uid,
      status: 'open',
      skillLevel: _selectedSkill,
      dateTime: matchDateTime,
      createdAt: DateTime.now(),
      balancedMode: _balancedMode,
    );

    // Call host controller
    final matchId = await ref.read(matchControllerProvider.notifier).hostMatch(newMatch);

    if (matchId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match hosted successfully!'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate straight to Match details lobby
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MatchDetailScreen(matchId: matchId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(matchControllerProvider);
    final isLoading = controllerState is AsyncLoading;

    // Listen to handle submission errors
    ref.listen<AsyncValue<void>>(matchControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final formattedDate = DateFormat('EEEE, MMMM d, y').format(_selectedDate);
    final formattedTime = _selectedTime.format(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Host a Match'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Title Input
                const Text(
                  'MATCH NAME',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 5v5 Friday Football Night',
                    prefixIcon: Icon(Icons.sports_soccer_outlined, color: AppTheme.textSecondaryColor),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Match name is required';
                    if (val.trim().length < 4) return 'Name must be at least 4 characters';
                    return null;
                  },
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),

                // 2. Sport selection Dropdown
                const Text(
                  'SPORT CATEGORY',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedSport,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.sports, color: AppTheme.textSecondaryColor),
                  ),
                  items: AppConstants.sports.map((String sport) {
                    return DropdownMenuItem<String>(
                      value: sport,
                      child: Text(sport),
                    );
                  }).toList(),
                  onChanged: isLoading
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSport = val;
                            });
                          }
                        },
                ),
                const SizedBox(height: 24),

                // 3. Venue input
                const Text(
                  'VENUE ADDRESS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _venueController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Astro Turf Arena, T-Nagar',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.textSecondaryColor),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Venue address is required';
                    if (val.trim().length < 4) return 'Address must be at least 4 characters';
                    return null;
                  },
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),

                // Simulated Location Coordinates (for Phase 3 Maps)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LATITUDE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            initialValue: _latitude.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(contentPadding: EdgeInsets.all(12)),
                            onChanged: (val) => _latitude = double.tryParse(val) ?? 13.0827,
                            enabled: !isLoading,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LONGITUDE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            initialValue: _longitude.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(contentPadding: EdgeInsets.all(12)),
                            onChanged: (val) => _longitude = double.tryParse(val) ?? 80.2707,
                            enabled: !isLoading,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Date & Time Selection Row
                Row(
                  children: [
                    // Date Card
                    Expanded(
                      child: GestureDetector(
                        onTap: isLoading ? null : _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DATE', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Time Card
                    Expanded(
                      child: GestureDetector(
                        onTap: isLoading ? null : _selectTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('START TIME', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                formattedTime,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Max Players Count & Skill constraints
                Row(
                  children: [
                    // Max Players
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MAX PLAYERS',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _maxPlayersController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.people_outline, color: AppTheme.textSecondaryColor),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              final num = int.tryParse(val);
                              if (num == null || num < 2) return 'Must be >= 2';
                              if (num > 50) return 'Max limit is 50';
                              return null;
                            },
                            enabled: !isLoading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Skill Limit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TARGET SKILL',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedSkill,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.grade_outlined, color: AppTheme.textSecondaryColor),
                            ),
                            items: AppConstants.skillLevels.map((String skill) {
                              return DropdownMenuItem<String>(
                                value: skill,
                                child: Text(skill),
                              );
                            }).toList(),
                            onChanged: isLoading
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedSkill = val;
                                      });
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 6. Balanced Mode Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.balance_rounded, color: AppTheme.secondaryColor, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enable Balanced Mode',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Auto-recommends player slots based on joined player average skill.',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _balancedMode,
                        activeColor: AppTheme.secondaryColor,
                        onChanged: isLoading
                            ? null
                            : (val) {
                                setState(() {
                                  _balancedMode = val;
                                });
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text('Host Match'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
