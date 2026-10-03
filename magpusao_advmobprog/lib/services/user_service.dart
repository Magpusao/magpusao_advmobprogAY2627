import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  static const String profileImageAsset = 'assets/images/smart_cat.png';
  static const String profileFirstName = 'Emily';
  static const String profileLastName = 'Johnson';
  static const String profileUsername = 'emilys';
  static const String profileEmail = 'emily.johnson@x.dummyjson.com';
  static const String loginPassword = 'emilyspass';

  static const String _apiUsername = 'emilys';
  static const String _apiPassword = 'emilyspass';

  firebase_auth.FirebaseAuth get _firebaseAuth =>
      firebase_auth.FirebaseAuth.instance;

  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _saveFirebaseSession(credential.user);
    return credential;
  }

  Future<firebase_auth.UserCredential> createAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(username.trim());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', 'firebase');
    await prefs.setString('firebaseUid', credential.user?.uid ?? '');
    await prefs.setString('username', username.trim());
    await prefs.setString('email', email.trim());
    await prefs.setString('firstName', firstName.trim());
    await prefs.setString('lastName', lastName.trim());
    await prefs.setInt('age', age);
    await prefs.setString('contactNo', contactNo.trim());
    await prefs.setString('image', profileImageAsset);
    return credential;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _clearSession();
  }

  Future<void> updateUsername(String username) async {
    final value = username.trim();
    if (value.isEmpty) throw ArgumentError('Username cannot be empty.');
    await _firebaseAuth.currentUser?.updateDisplayName(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', value);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('No Firebase user is signed in.');
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    await user.delete();
    await _clearSession();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw StateError('No email/password user is signed in.');
    }
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> _saveFirebaseSession(firebase_auth.User? user) async {
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', 'firebase');
    await prefs.setString('firebaseUid', user.uid);
    await prefs.setString('email', user.email ?? '');
    if ((prefs.getString('username') ?? '').isEmpty) {
      await prefs.setString('username', user.displayName ?? user.email ?? '');
    }
    await prefs.setString('accessToken', await user.getIdToken() ?? '');
  }

  static bool acceptsCredentials(String username, String password) {
    return username.trim() == profileUsername && password == loginPassword;
  }

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    if (!acceptsCredentials(username, password)) {
      throw Exception('Invalid username or password.');
    }

    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _apiUsername,
        'password': _apiPassword,
        'expiresInMins': 30,
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
      return {
        ...decoded,
        'username': profileUsername,
        'email': profileEmail,
        'firstName': profileFirstName,
        'lastName': profileLastName,
        'image': profileImageAsset,
      };
    }

    final message = decoded is Map<String, dynamic>
        ? decoded['message']?.toString()
        : null;
    throw Exception(message ?? 'Unable to sign in. Please try again.');
  }

  Future<void> saveUserData(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(response);

    await prefs.setInt('user_id', user.id);
    await prefs.setString('username', profileUsername);
    await prefs.setString('email', profileEmail);
    await prefs.setString('firstName', profileFirstName);
    await prefs.setString('lastName', profileLastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', profileImageAsset);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setString('loginType', 'dummyJson');
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('loginType') == 'firebase') {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;
      return {
        'id': firebaseUser.uid.hashCode & 0x7fffffff,
        'uid': firebaseUser.uid,
        'username':
            prefs.getString('username') ?? firebaseUser.displayName ?? '',
        'email': firebaseUser.email ?? prefs.getString('email') ?? '',
        'firstName': prefs.getString('firstName') ?? '',
        'lastName': prefs.getString('lastName') ?? '',
        'age': prefs.getInt('age'),
        'contactNo': prefs.getString('contactNo') ?? '',
        'gender': prefs.getString('gender') ?? '',
        'image': prefs.getString('image') ?? profileImageAsset,
        'accessToken': await firebaseUser.getIdToken() ?? '',
        'refreshToken': '',
        'loginType': 'firebase',
      };
    }
    final id = prefs.getInt('user_id');
    final accessToken = prefs.getString('accessToken') ?? '';

    if (id == null || accessToken.isEmpty) return null;

    return {
      'id': id,
      'username': profileUsername,
      'email': profileEmail,
      'firstName': profileFirstName,
      'lastName': profileLastName,
      'gender': prefs.getString('gender') ?? '',
      'image': profileImageAsset,
      'accessToken': accessToken,
      'refreshToken': prefs.getString('refreshToken') ?? '',
    };
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('loginType') == 'firebase') {
      return _firebaseAuth.currentUser != null;
    }
    return (prefs.getString('accessToken') ?? '').isNotEmpty;
  }

  Future<String> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginType') ?? 'none';
  }

  Future<void> logout() async {
    if (Firebase.apps.isNotEmpty && _firebaseAuth.currentUser != null) {
      await _firebaseAuth.signOut();
    }
    await _clearSession();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
