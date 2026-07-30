import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routing/app_router.dart';
import '../../shared/services/gemma_service.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/emergency_facilities_service.dart';
import '../../shared/services/database_service.dart';
import '../../features/medical_profile/data/repositories/profile_repository.dart';
import '../../features/emergency/data/repositories/emergency_repository.dart';
import '../../features/medical_profile/data/models/medical_profile.dart';
import '../../features/emergency/data/models/emergency_session.dart';

final routerProvider = Provider((ref) => AppRouter.router);

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final gemmaServiceProvider = ChangeNotifierProvider<GemmaService>((ref) {
  return GemmaService();
});

final locationServiceProvider = ChangeNotifierProvider<LocationService>((ref) {
  return LocationService();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(databaseServiceProvider));
});

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(ref.watch(databaseServiceProvider));
});

final emergencyFacilitiesServiceProvider =
    Provider<EmergencyFacilitiesService>((ref) {
  return EmergencyFacilitiesService(ref.watch(locationServiceProvider));
});

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, MedicalProfile?>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<MedicalProfile?> {
  @override
  Future<MedicalProfile?> build() async {
    final repo = ref.read(profileRepositoryProvider);
    return repo.getProfile();
  }

  Future<void> saveProfile(MedicalProfile profile) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.saveProfile(profile);
    state = AsyncData(profile);
  }

  Future<void> refresh() async {
    final repo = ref.read(profileRepositoryProvider);
    final profile = await repo.getProfile();
    state = AsyncData(profile);
  }
}

final currentEmergencyProvider =
    StateNotifierProvider<EmergencyNotifier, EmergencySession?>(
  (ref) => EmergencyNotifier(ref),
);

class EmergencyNotifier extends StateNotifier<EmergencySession?> {
  final Ref _ref;

  EmergencyNotifier(this._ref) : super(null);

  void startNewSession() {
    state = EmergencySession();
  }

  void updateDescription(String description) {
    if (state == null) return;
    state = state!.copyWith(emergencyDescription: description);
  }

  void addImagePath(String path) {
    if (state == null) return;
    final images = List<String>.from(state!.imagePaths)..add(path);
    state = state!.copyWith(imagePaths: images);
  }

  void setAudioPath(String path) {
    if (state == null) return;
    state = state!.copyWith(audioPath: path);
  }

  void setEmergencyType(String type) {
    if (state == null) return;
    state = state!.copyWith(emergencyType: type);
  }

  void setAiAssessment(String assessment) {
    if (state == null) return;
    state = state!.copyWith(aiAssessment: assessment);
  }

  void setImmediateActions(List<String> actions) {
    if (state == null) return;
    state = state!.copyWith(immediateActions: actions);
  }

  void setThingsToAvoid(List<String> avoid) {
    if (state == null) return;
    state = state!.copyWith(thingsToAvoid: avoid);
  }

  void setMonitor(List<String> monitor) {
    if (state == null) return;
    state = state!.copyWith(monitor: monitor);
  }

  void setWhenToSeekCare(String seekCare) {
    if (state == null) return;
    state = state!.copyWith(whenToSeekCare: seekCare);
  }

  void addFollowUp(String question, String answer) {
    if (state == null) return;
    final questions =
        List<String>.from(state!.followUpQuestions)..add(question);
    final answers = List<String>.from(state!.followUpAnswers)..add(answer);
    state = state!.copyWith(
      followUpQuestions: questions,
      followUpAnswers: answers,
    );
  }

  void setSummary(String summary) {
    if (state == null) return;
    state = state!.copyWith(summary: summary);
  }

  Future<void> completeSession() async {
    if (state == null) return;
    state = state!.copyWith(isCompleted: true);
    await _ref.read(emergencyRepositoryProvider).createSession(state!);
    state = null;
  }

  void reset() {
    state = null;
  }
}

final sessionHistoryProvider =
    FutureProvider<List<EmergencySession>>((ref) async {
  final repo = ref.read(emergencyRepositoryProvider);
  return repo.getCompletedSessions();
});
