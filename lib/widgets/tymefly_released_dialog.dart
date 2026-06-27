import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class TymeFlyReleasedDialog extends StatefulWidget {
  const TymeFlyReleasedDialog({super.key});

  @override
  State<TymeFlyReleasedDialog> createState() => _TymeFlyReleasedDialogState();
}

class _TymeFlyReleasedDialogState extends State<TymeFlyReleasedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> scale;
  late final Animation<double> fade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    scale = CurvedAnimation(parent: controller, curve: Curves.elasticOut);
    fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget butterfly() {
    return ScaleTransition(
      scale: scale,
      child: FadeTransition(
        opacity: fade,
        child: Image.asset(
          'assets/logo/butterfly.png',
          width: 90,
          height: 90,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.flutter_dash_rounded,
              size: 86,
              color: AppTheme.primary,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          butterfly(),
          const SizedBox(height: 16),
          const Text(
            'Your TYMEFLY is Released',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'A future memory has unlocked. Open your timeline to view it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('View Timeline'),
            ),
          ),
        ],
      ),
    );
  }
}
