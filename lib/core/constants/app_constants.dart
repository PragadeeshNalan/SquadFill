/// Global constants used throughout the SquadFill application.
class AppConstants {
  // App Details
  static const String appName = 'SquadFill';

  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String matchesCollection = 'matches';
  static const String participantsCollection = 'participants';
  static const String notificationsCollection = 'notifications';

  // Sport Preference Values
  static const List<String> sports = [
    'Football',
    'Basketball',
    'Tennis',
    'Volleyball',
    'Badminton',
    'Cricket',
    'Padel',
    'Running'
  ];

  // Skill Levels
  static const String skillBeginner = 'Beginner';
  static const String skillIntermediate = 'Intermediate';
  static const String skillAdvanced = 'Advanced';

  static const List<String> skillLevels = [
    skillBeginner,
    skillIntermediate,
    skillAdvanced,
  ];

  // Map skill level text to integer value for balancing
  static int skillLevelToInt(String level) {
    switch (level) {
      case skillBeginner:
        return 1;
      case skillIntermediate:
        return 2;
      case skillAdvanced:
        return 3;
      default:
        return 1;
    }
  }

  // Map skill level integer to text
  static String skillLevelFromInt(int value) {
    switch (value) {
      case 1:
        return skillBeginner;
      case 2:
        return skillIntermediate;
      case 3:
        return skillAdvanced;
      default:
        return skillBeginner;
    }
  }

  // Pre-seeded local avatars for selection
  static const List<String> localAvatars = [
    'assets/images/avatar_1.png',
    'assets/images/avatar_2.png',
    'assets/images/avatar_3.png',
    'assets/images/avatar_4.png',
    'assets/images/avatar_5.png',
    'assets/images/avatar_6.png',
  ];
}
