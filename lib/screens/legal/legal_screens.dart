import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Privacy Policy',
      body: '''
TYMEFLY respects your privacy.

We collect account information, trusted contact details, uploaded media, messages, and release dates only to provide the TYMEFLY service.

Your photos, videos, text, and contacts are stored securely using Firebase services.

We do not sell your personal memories or trusted contact information.

You may delete your account from the Profile screen.

Contact:
alerttmenow@gmail.com

Website:
www.an2app.com
''',
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Terms of Service',
      body: '''
By using TYMEFLY, you agree to use the app responsibly.

TYMEFLY allows users to create future memories using photos, videos, text, and AI-generated content.

You are responsible for the content you upload and the contacts you choose.

Do not upload illegal, harmful, abusive, or unauthorized content.

Subscription features may be billed through Google Play or the Apple App Store.

TYMEFLY may update these terms as the app improves.

Contact:
alerttmenow@gmail.com

Website:
www.an2app.com
''',
    );
  }
}

class AboutTymeFlyScreen extends StatelessWidget {
  const AboutTymeFlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'About TYMEFLY',
      body: '''
TYMEFLY helps you capture memories today and release them in the future.

You can create future memories using text, photos, videos, and AI-powered future letters.

App Name:
TYMEFLY

Developer:
AN2App

Website:
www.an2app.com

Support:
alerttmenow@gmail.com
''',
    );
  }
}

class _LegalPage extends StatelessWidget {
  final String title;
  final String body;

  const _LegalPage({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
