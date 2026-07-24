import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:squadfill/presentation/providers/auth_providers.dart';
import 'package:squadfill/presentation/providers/match_providers.dart';
import 'package:squadfill/presentation/screens/match_detail_screen.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/core/constants/app_constants.dart';
import 'package:squadfill/data/models/match_model.dart';
import 'package:squadfill/presentation/screens/map/location_picker_screen.dart';
import 'package:latlong2/latlong.dart';

/// Form screen allowing authenticated users to schedule and host a new match.
class CreateMatchScreen extends ConsumerStatefulWidget {
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

  // Defaults (Chennai)
  double _latitude = 13.0827;
  double _longitude = 80.2707;

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _maxPlayersController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppTheme.primaryColor,
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppTheme.primaryColor,
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickLocation() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentSquadUserProvider);
    if (user == null) return;

    final DateTime matchDateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    if (matchDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Matches must be scheduled in the future!'),
        backgroundColor: AppTheme.errorColor,
      ));
      return;
    }

    final int maxPlayers = int.tryParse(_maxPlayersController.text) ?? 10;

    final newMatch = MatchModel(
      matchId: '',
      title: _titleController.text.trim(),
      sport: _selectedSport,
      venue: _venueController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      maxPlayers: maxPlayers,
      currentPlayers: 1,
      organizerId: user.uid,
      status: 'open',
      skillLevel: _selectedSkill,
      dateTime: matchDateTime,
      createdAt: DateTime.now(),
      balancedMode: _balancedMode,
    );

    final matchId = await ref.read(matchControllerProvider.notifier).hostMatch(newMatch);

    if (matchId != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MatchDetailScreen(matchId: matchId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(matchControllerProvider) is AsyncLoading;
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(_selectedDate);
    final formattedTime = _selectedTime.format(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Host a Match')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Match Name
                const Text('MATCH NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: 'e.g. 5v5 Friday Football'),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),

                // 2. Sport Category
                const Text('SPORT CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedSport,
                  items: AppConstants.sports.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: isLoading ? null : (val) => setState(() => _selectedSport = val!),
                ),
                const SizedBox(height: 24),

                // 3. Venue Address
                const Text('VENUE ADDRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _venueController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Astro Turf, T-Nagar',
                    suffixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),

                // 4. Map Picker (Optional phrasing removed)
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _pickLocation,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Pick Location on Map'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. GPS Coordinates (Manual Input fallback)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LATITUDE', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: ValueKey('lat_$_latitude'),
                            initialValue: _latitude.toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _latitude = double.tryParse(val) ?? 0.0,
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
                          const Text('LONGITUDE', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: ValueKey('lng_$_longitude'),
                            initialValue: _longitude.toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _longitude = double.tryParse(val) ?? 0.0,
                            enabled: !isLoading,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 6. Date & Time Selection
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isLoading ? null : _selectDate,
                        child: _buildPickerBox('DATE', formattedDate),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: isLoading ? null : _selectTime,
                        child: _buildPickerBox('START TIME', formattedTime),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 7. Max Players & Target Skill
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MAX PLAYERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _maxPlayersController,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              final num = int.tryParse(val);
                              if (num == null || num < 2) return 'Min 2';
                              return null;
                            },
                            enabled: !isLoading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TARGET SKILL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedSkill,
                            items: AppConstants.skillLevels.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: isLoading ? null : (val) => setState(() => _selectedSkill = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 8. Balanced Mode Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.balance, color: AppTheme.secondaryColor),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text('Enable Balanced Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Switch.adaptive(
                        value: _balancedMode,
                        activeColor: AppTheme.secondaryColor,
                        onChanged: isLoading ? null : (val) => setState(() => _balancedMode = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Host Match'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}