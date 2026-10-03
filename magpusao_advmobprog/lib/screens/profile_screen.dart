import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user = widget.user;
  bool _isFirebaseLogin = false;
  int? _age;
  String _contactNo = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final data = await UserService().getUserData();
      if (data == null || !mounted) return;
      setState(() {
        _user = User.fromJson(data);
        _isFirebaseLogin = data['loginType'] == 'firebase';
        _age = data['age'] as int?;
        _contactNo = data['contactNo'] as String? ?? '';
      });
    } catch (_) {
      // Keep showing the user passed by Home when Firebase is unavailable.
    }
  }

  Future<void> _logout(BuildContext context) async {
    await UserService().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  Future<String?> _ask(String title, {bool obscure = false}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _updateUsername() async {
    final username = await _ask('New username');
    if (username == null || username.trim().isEmpty) return;
    await UserService().updateUsername(username);
    await _loadUser();
  }

  Future<void> _changePassword() async {
    final current = await _ask('Current password', obscure: true);
    if (current == null) return;
    final replacement = await _ask('New password', obscure: true);
    if (replacement == null || replacement.length < 6) return;
    await UserService().resetPasswordFromCurrentPassword(
      currentPassword: current,
      newPassword: replacement,
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated.')));
    }
  }

  Future<void> _deleteAccount() async {
    final password = await _ask('Confirm password', obscure: true);
    if (password == null) return;
    await UserService().deleteAccount(email: _user.email, password: password);
    if (!mounted) return;
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
                    _user.fullName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '@${_user.username}',
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
            value: '${_user.id}',
          ),
          _ProfileTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _user.email.isEmpty ? 'Not provided' : _user.email,
          ),
          _ProfileTile(
            icon: Icons.person_outline,
            label: 'Gender',
            value: _user.gender.isEmpty ? 'Not provided' : _user.gender,
          ),
          if (_isFirebaseLogin) ...[
            _ProfileTile(
              icon: Icons.cake_outlined,
              label: 'Age',
              value: _age?.toString() ?? 'Not provided',
            ),
            _ProfileTile(
              icon: Icons.phone_outlined,
              label: 'Contact number',
              value: _contactNo.isEmpty ? 'Not provided' : _contactNo,
            ),
            const _ProfileTile(
              icon: Icons.verified_user_outlined,
              label: 'Login type',
              value: 'Firebase',
            ),
          ],
          if (_isFirebaseLogin) ...[
            OutlinedButton.icon(
              onPressed: _updateUsername,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Update username'),
            ),
            OutlinedButton.icon(
              onPressed: _changePassword,
              icon: const Icon(Icons.password_outlined),
              label: const Text('Change password'),
            ),
            OutlinedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Delete account'),
            ),
          ],
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
