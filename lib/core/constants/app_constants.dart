class AppConstants {
  AppConstants._();

  static const String appName = 'ResQ';
  static const String tagline = 'Offline Emergency Intelligence';

  static const String defaultMedicalFacilitiesFile = 'assets/data/emergency_facilities.json';

  static const int maxRecentSessions = 20;

  static const List<String> supportedEmergencyTypes = [
    'Bleeding',
    'Burn',
    'Fracture',
    'Allergic Reaction',
    'Seizure',
    'Unconsciousness',
    'Choking',
    'Poisoning',
    'Animal Bite',
    'Electrical Injury',
    'Road Accident',
    'Fall',
    'Asthma Attack',
    'Other',
  ];
}
