import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final userService = UserService();
    TextInput.finishAutofillContext();
    setState(() => _isLoading = true);

    try {
      final response = await userService.loginUser(
        _usernameController.text,
        _passwordController.text,
      );
      await userService.saveUserData(response);

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/home', arguments: response);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${error.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(28.w, 28.h, 28.w, 24.h),
              children: [
                Align(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34.r),
                    child: Image.asset(
                      'assets/images/cat.png',
                      key: const Key('signInLogo'),
                      width: 138.w,
                      height: 138.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 26.h),
                Text(
                  'Welcome back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 7.h),
                Text(
                  'Sign in to continue shopping.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 28.h),
                TextFormField(
                  key: const Key('signInUsername'),
                  controller: _usernameController,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your username'
                      : null,
                ),
                SizedBox(height: 14.h),
                TextFormField(
                  key: const Key('signInPassword'),
                  controller: _passwordController,
                  autofillHints: const [AutofillHints.password],
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your password'
                      : null,
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  height: 54.h,
                  child: FilledButton(
                    key: const Key('signInButton'),
                    onPressed: _isLoading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.secondary,
                      foregroundColor: colors.onSecondary,
                    ),
                    child: _isLoading
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  padding: EdgeInsets.all(13.w),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Text(
                    'Username: Meow  •  Password: Meow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
