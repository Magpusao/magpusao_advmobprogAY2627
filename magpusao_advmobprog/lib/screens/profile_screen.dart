import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user});

  final User user;

  Future<void> _logout(BuildContext context) async {
    await UserService().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(22.r),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  const _ProfileImage(assetPath: UserService.profileImageAsset),
                  SizedBox(height: 14.h),
                  Text(
                    user.fullName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
          _ProfileTile(
            icon: Icons.badge_outlined,
            label: 'User ID',
            value: '${user.id}',
          ),
          _ProfileTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email.isEmpty ? 'Not provided' : user.email,
          ),
          _ProfileTile(
            icon: Icons.person_outline,
            label: 'Gender',
            value: user.gender.isEmpty ? 'Not provided' : user.gender,
          ),
          SizedBox(height: 6.h),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.palette_outlined),
            label: const Text('Appearance settings'),
          ),
          SizedBox(height: 10.h),
          FilledButton.icon(
            key: const Key('logoutButton'),
            onPressed: () => _logout(context),
            style: FilledButton.styleFrom(
              backgroundColor: colors.errorContainer,
              foregroundColor: colors.onErrorContainer,
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox.square(
        dimension: 104.w,
        child: Image.asset(
          assetPath,
          key: const Key('profileImage'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 10.h),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
