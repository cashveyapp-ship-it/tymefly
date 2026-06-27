import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../ai/ai_studio_screen.dart';
import '../contacts/contacts_screen.dart';
import '../create/create_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';
import '../timeline/timeline_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      CreateScreen(
        onAiPlusCreated: () {
          setState(() => index = 3);
        },
      ),
      const TimelineScreen(),
      const AiStudioScreen(),
      const ContactsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        indicatorColor: AppTheme.primary.withValues(alpha: .12),
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add_circle_rounded), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.timeline_rounded), label: 'Timeline'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_rounded), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.group_rounded), label: 'Contacts'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}







