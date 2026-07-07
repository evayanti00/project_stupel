import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../services/settings_provider.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  User? _profile;

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
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final rawUser = data['user'] as Map<String, dynamic>? ?? {};
        _profile = User.fromJson(rawUser);
        context.read<AuthProvider>().setUserFromProfile(rawUser);
      } else {
        setState(() => _error = res['message']);
      }
    } catch (_) {
      setState(() => _error = 'Gagal memuat profil');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile({
    required String name,
    required String phone,
    required String bio,
    String? profilePhotoUrl,
  }) async {
    if (_profile == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = {
        'name': name,
        'email': _profile!.email,
        'phone': phone,
        'bio': bio,
        'profile_photo_url': profilePhotoUrl ?? _profile!.profilePhotoUrl,
      };
      final res = await ApiService.updateProfile(body);
      if (res['success'] == true) {
        final user = res['data'] as Map<String, dynamic>;
        await context.read<AuthProvider>().setUserFromProfile(user);
        _profile = User.fromJson(user);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
        await _load();
      } else {
        setState(() => _error = res['message']);
      }
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _changePhoto() async {
    if (_profile == null) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _saving = true);
    final upload = await ApiService.uploadProfilePhoto(picked.path);
    final url = upload['data']?['url']?.toString();
    if (!mounted) return;

    if (url == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(upload['message']?.toString() ?? 'Upload foto gagal')),
      );
      return;
    }

    await _saveProfile(
      name: _profile!.name,
      phone: _profile!.phone ?? '',
      bio: _profile!.bio ?? '',
      profilePhotoUrl: url,
    );
  }

  Future<void> _showEditProfileSheet() async {
    if (_profile == null) return;
    final nameCtrl = TextEditingController(text: _profile!.name);
    final phoneCtrl = TextEditingController(text: _profile!.phone ?? '');
    final bioCtrl = TextEditingController(text: _profile!.bio ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Profil', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Nomor Telepon')),
            const SizedBox(height: 10),
            TextField(
              controller: bioCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _saveProfile(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          bio: bioCtrl.text.trim(),
                        );
                      },
                child: const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final passCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Password'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password Baru'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (passCtrl.text.trim().length < 6) return;
              Navigator.pop(ctx);
              setState(() => _saving = true);
              final res = await ApiService.updateProfile({
                'name': _profile?.name ?? '',
                'email': _profile?.email ?? '',
                'phone': _profile?.phone ?? '',
                'bio': _profile?.bio ?? '',
                'profile_photo_url': _profile?.profilePhotoUrl ?? '',
                'password': passCtrl.text.trim(),
              });
              if (!mounted) return;
              setState(() => _saving = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message'] ?? 'Password diperbarui')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _profile ?? context.watch<AuthProvider>().user;
    final settings = context.watch<SettingsProvider>();
    final joined = user?.createdAt != null
        ? DateFormat('d MMMM yyyy', 'id').format(user!.createdAt!)
        : '-';

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Profile')),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundImage: (user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty)
                                  ? NetworkImage(user.profilePhotoUrl!)
                                  : null,
                              child: (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty)
                                  ? Text(
                                    (((user?.name ?? '').isNotEmpty ? user!.name[0] : 'U')).toUpperCase(),
                                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: _saving ? null : _changePhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(user?.name ?? '-', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(user?.email ?? '-', style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChipInfo(label: 'Role', value: user?.role ?? '-'),
                            _ChipInfo(label: 'Telepon', value: (user?.phone?.isNotEmpty ?? false) ? user!.phone! : '-'),
                            _ChipInfo(label: 'Bergabung', value: joined),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            user?.bio?.isNotEmpty == true ? user!.bio! : 'Belum ada bio',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Pengaturan Akun', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Edit Profile'),
                        onTap: _showEditProfileSheet,
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock_reset),
                        title: const Text('Ganti Password'),
                        onTap: _showChangePasswordDialog,
                      ),
                      SwitchListTile(
                        value: settings.isDarkMode,
                        onChanged: (_) => settings.toggleTheme(),
                        title: const Text('Dark Mode'),
                        secondary: const Icon(Icons.dark_mode_outlined),
                      ),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Tentang Aplikasi'),
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'STUPEL',
                            applicationVersion: '1.0.0',
                            applicationLegalese: 'Student Planner App',
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: AppColors.danger),
                        title: const Text('Logout', style: TextStyle(color: AppColors.danger)),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  final String label;
  final String value;
  const _ChipInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
    );
  }
}
