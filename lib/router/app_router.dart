import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/calendar_sync_screen.dart';
import '../screens/driving_mode_screen.dart';
import '../screens/family_calendar_screen.dart';
import '../screens/month_view_screen.dart';
import '../screens/quick_poll_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/share_calendar_screen.dart';
import '../screens/shared_calendar_view_screen.dart';
import '../screens/time_report_screen.dart';
import '../screens/voice_templates_screen.dart';
import '../screens/week_view_screen.dart';
import 'home_shell.dart';

GoRouter createAppRouter({required AuthProvider authListenable}) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isSharedRoute = location.startsWith('/shared/');
      final isPollRoute = location.startsWith('/poll/');
      final isAuthenticated = authListenable.isAuthenticated;
      final isAuthRoute = location == '/auth';

      // Public viewer routes (share links + poll participation).
      if (isSharedRoute || isPollRoute) {
        return null;
      }

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SizedBox.shrink(),
            ),
          ),
          GoRoute(
            path: '/week',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WeekViewScreen(embeddedInShell: true),
            ),
          ),
          GoRoute(
            path: '/month',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MonthViewScreen(embeddedInShell: true),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/driving',
        builder: (context, state) => const DrivingModeScreen(),
      ),
      GoRoute(
        path: '/calendar-sync',
        builder: (context, state) => const CalendarSyncScreen(),
      ),
      GoRoute(
        path: '/voice-templates',
        builder: (context, state) => const VoiceTemplatesScreen(),
      ),
      GoRoute(
        path: '/family',
        builder: (context, state) => const FamilyCalendarScreen(),
      ),
      GoRoute(
        path: '/share',
        builder: (context, state) => const ShareCalendarScreen(),
      ),
      GoRoute(
        path: '/poll/:pollId',
        builder: (context, state) => QuickPollScreen(
          pollId: state.pathParameters['pollId'],
        ),
      ),
      GoRoute(
        path: '/poll',
        builder: (context, state) => const QuickPollScreen(),
      ),
      GoRoute(
        path: '/time-report',
        builder: (context, state) => const TimeReportScreen(),
      ),
      GoRoute(
        path: '/shared/:code',
        builder: (context, state) => SharedCalendarViewScreen(
          code: state.pathParameters['code']!,
        ),
      ),
    ],
  );
}
