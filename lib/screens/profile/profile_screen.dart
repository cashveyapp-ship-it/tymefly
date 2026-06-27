import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/admin/admin_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/account_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../subscriptions/subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  bool uploadingPhoto = false;

  User? get user => FirebaseAuth.instance.currentUser;

  Future<void> updateProfilePhoto() async {
    final currentUser = user;
    if (currentUser == null) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() => uploadingPhoto = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('profile')
          .child('profile_photo.jpg');

      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await currentUser.updatePhotoURL(url);
      await currentUser.reload();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update photo: $e')),
      );
    } finally {
      if (mounted) setState(() => uploadingPhoto = false);
    }
  }

  Future<void> updateUsername() async {
    await user?.updateDisplayName(nameController.text.trim());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Username updated')),
    );

    setState(() {});
  }

  Future<void> sendPasswordReset() async {
    final email = user?.email;
    if (email == null) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent')),
    );
  }

  Future<void> deleteAccount() async {
    try {
      await AccountService.deleteAccountData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete account: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    nameController.text = user?.displayName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    final photoUrl = currentUser?.photoURL;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppTheme.primary.withValues(alpha: .12),
                  backgroundImage: photoUrl == null || photoUrl.isEmpty
                      ? null
                      : NetworkImage(photoUrl),
                  child: photoUrl == null || photoUrl.isEmpty
                      ? const Icon(Icons.person_rounded, size: 44, color: AppTheme.primary)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppTheme.primary,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: uploadingPhoto
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                      onPressed: uploadingPhoto ? null : updateProfilePhoto,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              currentUser?.email ?? '',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 28),

          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: updateUsername,
            child: const Text('Update Username'),
          ),

          const SizedBox(height: 20),

          if (AdminConfig.isAdmin(currentUser?.email)) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
              label: const Text('Admin Dashboard'),
            ),
            const SizedBox(height: 12),
          ],

          OutlinedButton.icon(
            icon: const Icon(Icons.workspace_premium_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            label: const Text('View Plans & AI+'),
          ),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: sendPasswordReset,
            child: const Text('Change Password'),
          ),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),

          const SizedBox(height: 20),

          OutlinedButton(
            onPressed: deleteAccount,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}


