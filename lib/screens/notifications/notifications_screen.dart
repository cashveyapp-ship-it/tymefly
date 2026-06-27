import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  bool _enabled = false;

  Future<void> _loadNotificationStatus() async {
    final enabled = await NotificationService.getNotificationsEnabled();

    if (!mounted) return;

    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _loading = true;
      _enabled = value;
    });

    if (value) {
      await NotificationService.init(context: context);
    } else {
      await NotificationService.setNotificationsEnabled(false);
    }

    if (!mounted) return;

    setState(() {
      _enabled = value;
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Notifications turned on' : 'Notifications turned off',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE9E9EF)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEDE7FF)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  size: 48,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _enabled ? 'Notifications are active' : 'Notifications are off',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'TYMEFLY will notify you when a future memory is released.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  value: _enabled,
                  onChanged: _loading ? null : _toggleNotifications,
                  title: const Text(
                    'Push Notifications',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    _enabled
                        ? 'Release alerts are turned on.'
                        : 'Release alerts are turned off.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
