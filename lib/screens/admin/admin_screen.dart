import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../theme.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _loading = true;
  List<dynamic> _users = [];
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final usersRes = await ApiService.getAdminUsers();
      final statsRes = await ApiService.getAdminStats();
      if (!mounted) return;
      if (usersRes['success'] == true && statsRes['success'] == true) {
        setState(() {
          _users = usersRes['data'] as List<dynamic>? ?? [];
          _stats = statsRes['data'] as Map<String, dynamic>?;
        });
      } else {
        setState(() => _error = usersRes['message'] ?? statsRes['message']);
      }
    } catch (_) {
      setState(() => _error = 'Gagal memuat data admin');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(int id) async {
    final res = await ApiService.toggleUser(id);
    if (!mounted) return;
    if (res['success'] == true) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal mengubah status')));
    }
  }

  Future<void> _delete(int id) async {
    final res = await ApiService.deleteUser(id);
    if (!mounted) return;
    if (res['success'] == true) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal menghapus')));
    }
  }

  Future<void> _showDetail(Map<String, dynamic> user) async {
    final res = await ApiService.getAdminUserDetail(user['id'] as int);
    if (!mounted) return;
    if (res['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal memuat detail')));
      return;
    }
    final data = res['data'] as Map<String, dynamic>?;
    final detailUser = data?['user'] as Map<String, dynamic>? ?? {};
    final stats = data?['stats'] as Map<String, dynamic>? ?? {};
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(detailUser['name'] ?? user['name'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${detailUser['email'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Role: ${detailUser['role'] ?? 'user'}'),
            Text('Status Aktif: ${detailUser['is_active'] == 1 ? 'Aktif' : 'Nonaktif'}'),
            Text('Total Tugas: ${stats['total_tasks'] ?? 0}'),
            Text('Total Notes: ${stats['total_notes'] ?? 0}'),
            Text('Total Pengeluaran: ${stats['total_expenses'] ?? 0}'),
            Text('Total Nilai Pengeluaran: Rp ${stats['total_expense_amount'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  BarChartGroupData _group(int x, num value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          color: AppColors.primary,
          width: 18,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  List<BarChartGroupData> _growthGroups() {
    final growth = (_stats?['user_growth'] as List<dynamic>? ?? []);
    if (growth.isEmpty) {
      return [_group(0, 0)];
    }
    return List<BarChartGroupData>.generate(
      growth.length,
      (i) => _group(i, (growth[i]['total'] ?? 0) as num),
    );
  }

  Widget _growthTitle(double value) {
    final growth = (_stats?['user_growth'] as List<dynamic>? ?? []);
    final index = value.toInt();
    if (index < 0 || index >= growth.length) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        (growth[index]['label'] ?? '').toString(),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  if (_stats != null) ...[
                    Text('Grafik Pertumbuhan Pengguna', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) => _growthTitle(value),
                                  ),
                                ),
                              ),
                              barGroups: _growthGroups(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text('Daftar Pengguna', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._users.map((u) => Card(
                    child: ListTile(
                      onTap: () => _showDetail(u),
                      title: Text(u['name'] ?? ''),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(u['email'] ?? ''),
                        Text('Role: ${u['role'] ?? 'user'} | Active: ${u['is_active'] == 1 ? 'Aktif' : 'Nonaktif'}'),
                        Text('Tugas: ${u['total_tasks'] ?? 0} | Notes: ${u['total_notes'] ?? 0} | Pengeluaran: ${u['total_expenses'] ?? 0}'),
                      ]),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'toggle') _toggle(u['id']);
                          if (value == 'delete') _delete(u['id']);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'toggle', child: Text('Aktif/Nonaktifkan')),
                          PopupMenuItem(value: 'delete', child: Text('Hapus')),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
    );
  }
}
