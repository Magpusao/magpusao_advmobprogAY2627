import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  static const String profileImageAsset = 'assets/images/smart_cat.png';
  static const String profileFirstName = 'Zandra';
  static const String profileLastName = 'Meow';
  static const String profileUsername = 'Meow';
  static const String profileEmail = 'zandra.meow@car.com';
  static const String loginPassword = 'Meow';

  static const String _apiUsername = 'emilys';
  static const String _apiPassword = 'emilyspass';

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
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
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
    return (prefs.getString('accessToken') ?? '').isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
