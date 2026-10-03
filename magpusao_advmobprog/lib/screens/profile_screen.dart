import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
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
  bool _isUpdatingAccount = false;

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

  Future<String?> _ask(
    String title, {
    bool obscure = false,
    String initialValue = '',
    String? Function(String value)? validator,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _TextEntryDialog(
        title: title,
        obscure: obscure,
        initialValue: initialValue,
        validator: validator,
      ),
    );
  }

  Future<void> _updateUsername() async {
    final username = await _ask(
      'New username',
      initialValue: _user.username,
      validator: (value) => value.trim().isEmpty
          ? 'Username cannot be empty.'
          : null,
    );
    if (username == null) return;

    await _performAccountUpdate(() async {
      await UserService().updateUsername(username);
      await _loadUser();
      _showMessage('Username updated in Firebase.');
    });
  }

  Future<void> _changePassword() async {
    final current = await _ask(
      'Current password',
      obscure: true,
      validator: (value) => value.isEmpty ? 'Enter your current password.' : null,
    );
    if (current == null) return;
    if (!mounted) return;
    final replacement = await _ask(
      'New password',
      obscure: true,
      validator: (value) => value.length < 6
          ? 'Password must be at least 6 characters.'
          : null,
    );
    if (replacement == null) return;

    await _performAccountUpdate(() async {
      await UserService().resetPasswordFromCurrentPassword(
        currentPassword: current,
        newPassword: replacement,
      );
      _showMessage('Password updated in Firebase.');
    });
  }

  Future<void> _performAccountUpdate(Future<void> Function() update) async {
    if (_isUpdatingAccount) return;
    setState(() => _isUpdatingAccount = true);
    try {
      await update();
    } on FirebaseAuthException catch (error) {
      _showMessage(_firebaseErrorMessage(error), isError: true);
    } on ArgumentError catch (error) {
      _showMessage(error.message?.toString() ?? 'Invalid value.', isError: true);
    } on StateError catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Unable to update the account. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdatingAccount = false);
    }
  }

  String _firebaseErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'wrong-password' || 'invalid-credential' =>
        'The current password is incorrect.',
      'weak-password' => 'Choose a stronger password.',
      'requires-recent-login' =>
        'Please sign in again before changing this account.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      _ => error.message ?? 'Firebase could not update the account.',
    };
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : null,
      ),
    );
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
              onPressed: _isUpdatingAccount ? null : _updateUsername,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Update username'),
            ),
            OutlinedButton.icon(
              onPressed: _isUpdatingAccount ? null : _changePassword,
              icon: const Icon(Icons.password_outlined),
              label: const Text('Change password'),
            ),
            OutlinedButton.icon(
              onPressed: _isUpdatingAccount ? null : _deleteAccount,
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

class _TextEntryDialog extends StatefulWidget {
  const _TextEntryDialog({
    required this.title,
    required this.obscure,
    required this.initialValue,
    this.validator,
  });

  final String title;
  final bool obscure;
  final String initialValue;
  final String? Function(String value)? validator;

  @override
  State<_TextEntryDialog> createState() => _TextEntryDialogState();
}

class _TextEntryDialogState extends State<_TextEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    _obscure = widget.obscure;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      widget.obscure ? _controller.text : _controller.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: widget.title,
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  )
                : null,
          ),
          validator: (value) => widget.validator?.call(value ?? ''),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
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
