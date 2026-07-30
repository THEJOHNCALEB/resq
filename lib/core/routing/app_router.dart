import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/gemma_init_screen.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/medical_profile/presentation/pages/profile_page.dart';
import '../../features/medical_profile/presentation/pages/edit_profile_page.dart';
import '../../features/emergency/presentation/pages/emergency_flow_page.dart';
import '../../features/emergency/presentation/pages/guidance_page.dart';
import '../../features/medical_summary/presentation/pages/summary_page.dart';
import '../../features/continue_to_care/presentation/pages/continue_to_care_page.dart';
import '../../features/care_history/presentation/pages/history_page.dart';
import '../../features/care_history/presentation/pages/session_detail_page.dart';

class AppRouter {
  AppRouter._();

  static const init = '/';
  static const home = '/home';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const emergencyFlow = '/emergency';
  static const guidance = '/guidance';
  static const summary = '/summary';
  static const continueToCare = '/continue-to-care';
  static const history = '/history';
  static const sessionDetail = '/history/:sessionId';

  static final router = GoRouter(
    initialLocation: init,
    routes: [
      GoRoute(
        path: init,
        name: 'init',
        builder: (context, state) => const GemmaInitScreen(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: emergencyFlow,
        name: 'emergencyFlow',
        builder: (context, state) => const EmergencyFlowPage(),
      ),
      GoRoute(
        path: guidance,
        name: 'guidance',
        builder: (context, state) => const GuidancePage(),
      ),
      GoRoute(
        path: summary,
        name: 'summary',
        builder: (context, state) => const SummaryPage(),
      ),
      GoRoute(
        path: continueToCare,
        name: 'continueToCare',
        builder: (context, state) => const ContinueToCarePage(),
      ),
      GoRoute(
        path: history,
        name: 'history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: sessionDetail,
        name: 'sessionDetail',
        builder: (context, state) {
          final sessionId = int.tryParse(state.pathParameters['sessionId'] ?? '') ?? 0;
          return SessionDetailPage(sessionId: sessionId);
        },
      ),
    ],
  );
}
