import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _age = TextEditingController();
  final _contactNo = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _age,
      _contactNo,
      _username,
      _email,
      _password,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await UserService().createAccount(
        email: _email.text,
        password: _password.text,
        firstName: _firstName.text,
        lastName: _lastName.text,
        age: int.parse(_age.text),
        contactNo: _contactNo.text,
        username: _username.text,
      );
      final data = await UserService().getUserData();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
        arguments: data,
      );
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? error.code);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Account creation failed: $message')),
    );
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Enter your $label' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(24.w),
            children: [
              _field(_firstName, 'First name', Icons.person_outline),
              _field(_lastName, 'Last name', Icons.person_outline),
              _field(
                _age,
                'Age',
                Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  return age == null || age < 1 || age > 120
                      ? 'Enter a valid age'
                      : null;
                },
              ),
              _field(
                _contactNo,
                'Contact number',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              _field(_username, 'Username', Icons.alternate_email),
              _field(
                _email,
                'Email address',
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Enter a valid email address',
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: TextFormField(
                  key: const Key('signupPassword'),
                  controller: _password,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => (value?.length ?? 0) < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
              ),
              SizedBox(height: 8.h),
              FilledButton(
                key: const Key('createAccountButton'),
                onPressed: _loading ? null : _createAccount,
                child: _loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator:
            validator ?? (value) => _required(value, label.toLowerCase()),
      ),
    );
  }
}
