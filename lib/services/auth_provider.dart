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
    if (token != null && name != null && email != null && id != null) {
      _user = User(id: id, name: name, email: email, role: role);
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      print('AuthProvider.login response: $res');
      if (res['success'] == true) {
        final data = res['data'];
        print('AuthProvider.login data: $data');
        if (data is Map<String, dynamic> && data['token'] != null && data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token'] as String);
          await prefs.setString('user_name', data['user']['name'] as String);
          await prefs.setString('user_email', data['user']['email'] as String);
          await prefs.setString('user_role', data['user']['role'] as String);
          await prefs.setInt('user_id', data['user']['id'] as int);
          _user = User.fromJson(data['user'] as Map<String, dynamic>);
          return null;
        }
        return 'Login response invalid';
      }
      return res['message'] ?? 'Login gagal';
    } catch (e, st) {
      // print error details to help debug connectivity issues
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
}
