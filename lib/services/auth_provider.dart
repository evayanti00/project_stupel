import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;

  User? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');
    final id = prefs.getInt('user_id');
    final role = prefs.getString('user_role') ?? 'user';
    final phone = prefs.getString('user_phone');
    final bio = prefs.getString('user_bio');
    final profilePhotoUrl = prefs.getString('user_profile_photo_url');
    final isVerified = prefs.getBool('user_is_verified') ?? false;
    final joined = prefs.getString('user_created_at');
    if (token != null && name != null && email != null && id != null) {
      _user = User(
        id: id,
        name: name,
        email: email,
        role: role,
        phone: phone,
        bio: bio,
        profilePhotoUrl: profilePhotoUrl,
        isVerified: isVerified,
        createdAt: joined != null ? DateTime.tryParse(joined) : null,
      );
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      if (res['success'] == true) {
        final data = res['data'];
        if (data is Map<String, dynamic> && data['token'] != null && data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token'] as String);
          await prefs.setString('user_name', data['user']['name'] as String);
          await prefs.setString('user_email', data['user']['email'] as String);
          await prefs.setString('user_role', data['user']['role'] as String);
          await prefs.setInt('user_id', data['user']['id'] as int);
          await prefs.setString('user_phone', (data['user']['phone'] ?? '').toString());
          await prefs.setString('user_bio', (data['user']['bio'] ?? '').toString());
          await prefs.setString('user_profile_photo_url', (data['user']['profile_photo_url'] ?? '').toString());
          await prefs.setBool('user_is_verified', data['user']['is_verified'] == 1 || data['user']['is_verified'] == true);
          if (data['user']['created_at'] != null) {
            await prefs.setString('user_created_at', data['user']['created_at'].toString());
          }
          _user = User.fromJson(data['user'] as Map<String, dynamic>);
          return null;
        }
        return 'Login response invalid';
      }
      return res['message'] ?? 'Login gagal';
    } catch (e, st) {
      final msg = 'AuthProvider.login exception: $e\n$st';
      print(msg);
      try {
        File('flutter_login_error.log')
            .writeAsStringSync(msg + '\n', mode: FileMode.append);
      } catch (_) {}
      return 'Tidak dapat terhubung ke server';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> register(String name, String email, String password, {String? token, double? balance}) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService.register(
        name,
        email,
        password,
        token: token,
        balance: balance,
      );
      if (res['success'] == true) return null;
      return res['message'] ?? 'Registrasi gagal';
    } catch (e, st) {
      final msg = 'AuthProvider.register exception: $e\n$st';
      print(msg);
      try {
        File('flutter_login_error.log')
            .writeAsStringSync(msg + '\n', mode: FileMode.append);
      } catch (_) {}
      return 'Tidak dapat terhubung ke server';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> setUserFromProfile(Map<String, dynamic> rawUser) async {
    final updated = User.fromJson(rawUser);
    _user = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', updated.name);
    await prefs.setString('user_email', updated.email);
    await prefs.setString('user_role', updated.role);
    await prefs.setString('user_phone', updated.phone ?? '');
    await prefs.setString('user_bio', updated.bio ?? '');
    await prefs.setString('user_profile_photo_url', updated.profilePhotoUrl ?? '');
    await prefs.setBool('user_is_verified', updated.isVerified);
    if (updated.createdAt != null) {
      await prefs.setString('user_created_at', updated.createdAt!.toIso8601String());
    }
    notifyListeners();
  }
}
