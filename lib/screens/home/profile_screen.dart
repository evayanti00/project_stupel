import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getProfile();
      if (res['success'] == true) {
        final u = res['data'];
        _nameCtrl.text = u['name'] ?? '';
        _emailCtrl.text = u['email'] ?? '';
      } else {
        setState(() => _error = res['message']);
      }
    } catch (_) {
      setState(() => _error = 'Gagal memuat profil');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      };
      if (_passCtrl.text.isNotEmpty) body['password'] = _passCtrl.text;
      final res = await ApiService.updateProfile(body);
          if (res['success'] == true) {
            final auth = context.read<AuthProvider>();
            // refresh local user info
            final user = res['data'];
            final sp = await SharedPreferences.getInstance();
            await sp.setString('user_name', user['name'] ?? '');
            await sp.setString('user_email', user['email'] ?? '');
            if (user['role'] != null) await sp.setString('user_role', user['role']);
            await auth.checkLogin();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil diperbarui'), backgroundColor: AppColors.success));
      } else {
        setState(() => _error = res['message']);
      }
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  ),
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama')), 
                const SizedBox(height: 12),
                TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')), 
                const SizedBox(height: 12),
                TextFormField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password (kosongkan jika tidak diubah)'), obscureText: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)) : const Text('Simpan'),
                  ),
                ),
              ],
            ),
    );
  }
}
