import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../theme.dart';
import '../notes/note_detail_screen.dart';

class DashboardTab extends StatefulWidget {
  final ValueNotifier<int>? refreshTrigger;

  const DashboardTab({super.key, this.refreshTrigger});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  DateTime? _lastUpdated;

  String _toPlainText(dynamic rawContent) {
    if (rawContent == null) return '';
    final text = rawContent.toString();
    try {
      final parsed = jsonDecode(text);
      if (parsed is List) {
        return parsed
            .whereType<Map>()
            .map((e) => (e['insert'] ?? '').toString())
            .join('')
            .trim();
      }
    } catch (_) {
      // Keep original text when content is not Quill delta JSON.
    }
    return text;
  }

  Future<void> _openTaskDetail(Map<String, dynamic> rawTask) async {
    final id = rawTask['id'];
    final title = (rawTask['title'] ?? '').toString();
    if (id is! int || title.isEmpty) return;

    final note = Note(
      id: id,
      title: title,
      content: (rawTask['content'] ?? '').toString(),
      isTask: true,
      isDone: (rawTask['is_done'] == 1 || rawTask['is_done'] == true),
      dueDate: rawTask['due_date'] != null && rawTask['due_date'].toString().isNotEmpty
          ? DateTime.tryParse(rawTask['due_date'].toString())
          : null,
      createdAt: rawTask['created_at'] != null
          ? (DateTime.tryParse(rawTask['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      images: const [],
      priority: rawTask['priority']?.toString(),
      status: rawTask['status']?.toString(),
      description: rawTask['description']?.toString(),
    );

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
    );

    if (updated == true) {
      await _load();
    }
  }

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger?.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(covariant DashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_load);
      widget.refreshTrigger?.addListener(_load);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getDashboard();
      if (!mounted) return;
      if (data['success'] != true) {
        setState(() => _error = data['message'] ?? 'Gagal memuat dashboard');
      } else {
        setState(() {
          _data = data['data'] as Map<String, dynamic>?;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _error = 'Terjadi kesalahan: ${e.toString()}');
      debugPrint('DashboardTab._load error: $e\n$st');
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> refresh() async => _load();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Selamat pagi'
        : now.hour < 17
            ? 'Selamat siang'
            : 'Selamat malam';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Greeting banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting,',
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(user?.name ?? 'Mahasiswa',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id').format(now),
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ringkasan', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                tooltip: 'Muat ulang',
              ),
            ],
          ),
          if (_lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Terakhir diperbarui: ${DateFormat('HH:mm:ss', 'id').format(_lastUpdated!)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),

          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Tugas Belum Selesai',
                    value: '${_data?['pending_tasks'] ?? 0}',
                    icon: Icons.task_alt_rounded,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Catatan',
                    value: '${_data?['total_notes'] ?? 0}',
                    icon: Icons.sticky_note_2_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pengeluaran: toggle minggu/bulan
            _ExpenseCard(
              weekAmount: ((_data?['week_expenses'] as num?) ?? 0).toDouble(),
              monthAmount: ((_data?['total_expenses'] as num?) ?? 0).toDouble(),
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'Tugas Prioritas',
              value: '${_data?['priority_tasks'] ?? 0}',
              icon: Icons.upcoming_rounded,
              color: AppColors.accent,
            ),
            const SizedBox(height: 12),
            // List upcoming tasks
            if (((_data?['upcoming_tasks'] as List?) ?? []).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var t in ((_data?['upcoming_tasks'] as List?) ?? []))
                    Card(
                      child: ListTile(
                        onTap: () => _openTaskDetail(t as Map<String, dynamic>),
                        title: Text(t['title'] ?? ''),
                        subtitle: Text(
                          _toPlainText(t['content']),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          t['due_date'] ?? '',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
          ],

          const SizedBox(height: 24),
          Text('Tips Hari Ini', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Catat tugasmu sekarang agar tidak ada yang terlewat! '
                    'Gunakan fitur centang untuk menandai tugas yang sudah selesai.',
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: wide
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(value,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
      ),
    );
  }
}

class _ExpenseCard extends StatefulWidget {
  final double weekAmount;
  final double monthAmount;

  const _ExpenseCard({required this.weekAmount, required this.monthAmount});

  @override
  State<_ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<_ExpenseCard> {
  String _view = 'month';

  @override
  Widget build(BuildContext context) {
    final value = _view == 'week' ? widget.weekAmount : widget.monthAmount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pengeluaran', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ToggleButtons(
                  isSelected: [_view == 'week', _view == 'month'],
                  onPressed: (i) => setState(() => _view = i == 0 ? 'week' : 'month'),
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  color: AppColors.primary,
                  fillColor: AppColors.primary,
                  children: const [Padding(padding: EdgeInsets.symmetric(horizontal:12), child: Text('Minggu')), Padding(padding: EdgeInsets.symmetric(horizontal:12), child: Text('Bulan'))],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.danger, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(value), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(_view == 'week' ? 'Pengeluaran Minggu Ini' : 'Total Pengeluaran Bulan Ini', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
