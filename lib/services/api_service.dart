import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost/project_stupel/backend/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── AUTH ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register.php'),
      headers: await _headers(auth: false),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login.php'),
        headers: await _headers(auth: false),
        body: jsonEncode({'email': email, 'password': password}),
      );
      // debug: print status and body to help diagnose connectivity/errors
      print('ApiService.login -> status: ${res.statusCode}, body: ${res.body}');
      return jsonDecode(res.body);
    } catch (e, st) {
      final msg = 'ApiService.login exception: $e\n$st';
      print(msg);
      try {
        File('flutter_login_error.log')
            .writeAsStringSync(msg + '\n', mode: FileMode.append);
      } catch (_) {}
      rethrow;
    }
  }

  // ── NOTES / TASKS ────────────────────────────────────────────────────────

  static Future<List<Note>> getNotes() async {
    final res = await http.get(
      Uri.parse('$baseUrl/notes/index.php'),
      headers: await _headers(),
    );
    final data = jsonDecode(res.body);
    return (data['data'] as List).map((e) => Note.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> createNote(Note note) async {
    final res = await http.post(
      Uri.parse('$baseUrl/notes/create.php'),
      headers: await _headers(),
      body: jsonEncode(note.toJson()),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateNote(Note note) async {
    final res = await http.put(
      Uri.parse('$baseUrl/notes/update.php?id=${note.id}'),
      headers: await _headers(),
      body: jsonEncode(note.toJson()),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteNote(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/notes/delete.php?id=$id'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  // ── EXPENSES ─────────────────────────────────────────────────────────────

  static Future<List<Expense>> getExpenses() async {
    final res = await http.get(
      Uri.parse('$baseUrl/expenses/index.php'),
      headers: await _headers(),
    );
    final data = jsonDecode(res.body);
    return (data['data'] as List).map((e) => Expense.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> createExpense(Expense e) async {
    final res = await http.post(
      Uri.parse('$baseUrl/expenses/create.php'),
      headers: await _headers(),
      body: jsonEncode(e.toJson()),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateExpense(Expense e) async {
    final res = await http.put(
      Uri.parse('$baseUrl/expenses/update.php?id=${e.id}'),
      headers: await _headers(),
      body: jsonEncode(e.toJson()),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteExpense(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/expenses/delete.php?id=$id'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  // ── DASHBOARD ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard.php'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }
}
