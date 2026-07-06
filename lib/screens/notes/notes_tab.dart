import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme.dart';
import 'note_form_screen.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab>
    with SingleTickerProviderStateMixin {
  List<Note> _notes = [];
  bool _loading = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _notes = await ApiService.getNotes();
    } catch (_) {}
    setState(() => _loading = false);
    // notify parent/dashboard to refresh counts
    try {
      final auth = context.read<AuthProvider>();
      auth.notifyListeners();
    } catch (_) {}
  }

  Future<void> _delete(Note note) async {
    await ApiService.deleteNote(note.id!);
    _load();
  }

  Future<void> _toggleDone(Note note) async {
    note.isDone = !note.isDone;
    await ApiService.updateNote(note);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final notes = _notes.where((n) => !n.isTask).toList();
    final tasks = _notes.where((n) => n.isTask).toList();
    final pendingTasks = tasks.where((t) => !t.isDone).length;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Catatan (${notes.length})'),
                Tab(text: 'Tugas ($pendingTasks pending)'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _NoteList(
                          items: notes,
                          onDelete: _delete,
                          onTap: _openForm,
                          onToggle: null),
                      _NoteList(
                          items: tasks,
                          onDelete: _delete,
                          onTap: _openForm,
                          onToggle: _toggleDone),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _openForm(Note? note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteFormScreen(note: note)),
    );
    if (result == true) _load();
  }
}

class _NoteList extends StatelessWidget {
  final List<Note> items;
  final Function(Note) onDelete;
  final Function(Note?) onTap;
  final Function(Note)? onToggle;

  const _NoteList({
    required this.items,
    required this.onDelete,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sticky_note_2_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              onToggle != null ? 'Belum ada tugas' : 'Belum ada catatan',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambahkan',
              style:
                  TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final note = items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Slidable(
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => onTap(note),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Edit',
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12)),
                  ),
                  SlidableAction(
                    onPressed: (_) => onDelete(note),
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Hapus',
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(12)),
                  ),
                ],
              ),
              child: Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: onToggle != null
                      ? Checkbox(
                          value: note.isDone,
                          onChanged: (_) => onToggle!(note),
                          activeColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        )
                      : Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                  title: Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      decoration: note.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: note.isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: note.content.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        )
                      : null,
                  onTap: () => onTap(note),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
