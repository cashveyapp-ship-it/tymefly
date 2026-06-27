import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/notification_service.dart';
import '../../services/user_profile_service.dart';
import '../home/main_shell.dart';
import '../onboarding/onboarding_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _seenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seenOnboarding') ?? false;
  }

  void _syncAfterLogin(BuildContext context) {
    Future.microtask(() async {
      try {
        await UserProfileService.createOrUpdateUserProfile();
        if (context.mounted) {
          await NotificationService.init(context: context);
        }
      } catch (_) {
        // Do not block login.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.idTokenChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user != null) {
          _syncAfterLogin(context);
          return const MainShell();
        }

        return FutureBuilder<bool>(
          future: _seenOnboarding(),
          builder: (context, onboardingSnapshot) {
            if (!onboardingSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return onboardingSnapshot.data == true
                ? const LoginScreen()
                : const OnboardingScreen();
          },
        );
      },
    );
  }
}
