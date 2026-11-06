import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_icons.dart';
import '../widgets/floating_nav_bar.dart';
import 'routes.dart';

/// Student tabs: Home, Reports, (+ New report), Notifications, Profile.
/// The + button is an action, not a tab, so nav indices 0, 1, 3, 4 map to
/// branches 0, 1, 2, 3.
class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.shell, this.hasUnread = false});

  final StatefulNavigationShell shell;
  final bool hasUnread;

  static const _actionIndex = 2;

  @override
  Widget build(BuildContext context) {
    final branch = shell.currentIndex;
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: branch >= _actionIndex ? branch + 1 : branch,
        onTap: (i) {
          if (i == _actionIndex) {
            context.push(Routes.newReport);
            return;
          }
          final target = i > _actionIndex ? i - 1 : i;
          // Tapping the current tab again returns to its first page.
          shell.goBranch(target, initialLocation: target == branch);
        },
        items: [
          const NavItem(icon: AppIcon.home, label: 'Home'),
          const NavItem(icon: AppIcon.reports, label: 'Reports'),
          const NavItem(
            icon: AppIcon.plus,
            label: 'New report',
            isAction: true,
          ),
          NavItem(
            icon: AppIcon.bell,
            label: 'Notifications',
            showBadge: hasUnread,
          ),
          const NavItem(icon: AppIcon.profile, label: 'Profile'),
        ],
      ),
    );
  }
}

/// Staff tabs: Dashboard, All reports, Profile (no + button).
class StaffShell extends StatelessWidget {
  const StaffShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: const [
          NavItem(icon: AppIcon.dashboard, label: 'Dashboard'),
          NavItem(icon: AppIcon.reports, label: 'All reports'),
          NavItem(icon: AppIcon.profile, label: 'Profile'),
        ],
      ),
    );
  }
}
