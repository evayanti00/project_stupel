import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme.dart';
import 'note_form_screen.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  List<Note> _tasks = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final notes = await ApiService.getNotes();
      _tasks = notes.where((n) => n.isTask).toList();
      await NotificationService.scheduleTaskDeadlineReminders(_tasks);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _delete(Note note) async {
    await ApiService.deleteNote(note.id!);
    await _load();
  }

  Future<void> _toggleDone(Note note) async {
    note.isDone = !note.isDone;
    await ApiService.updateNote(note);
    await _load();
  }

  void _openForm(Note? note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteFormScreen(note: note, initialIsTask: note == null),
      ),
    );
    if (result == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase();
    final tasks = _tasks
        .where((t) => query.isEmpty || t.title.toLowerCase().contains(query) || t.plainContent.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari tugas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: tasks.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 140),
                              Center(child: Text('Belum ada tugas')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: tasks.length,
                            itemBuilder: (_, i) {
                              final task = tasks[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Slidable(
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) => _openForm(task),
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        icon: Icons.edit,
                                        label: 'Edit',
                                      ),
                                      SlidableAction(
                                        onPressed: (_) => _delete(task),
                                        backgroundColor: AppColors.danger,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete,
                                        label: 'Hapus',
                                      ),
                                    ],
                                  ),
                                  child: Card(
                                    child: ListTile(
                                      leading: Checkbox(
                                        value: task.isDone,
                                        onChanged: (_) => _toggleDone(task),
                                      ),
                                      title: Text(
                                        task.title,
                                        style: TextStyle(
                                          decoration: task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                        ),
                                      ),
                                      subtitle: Text(
                                        task.plainContent,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: task.dueDate != null
                                          ? Text(
                                              '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            )
                                          : null,
                                      onTap: () => _openForm(task),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-tasks',
        onPressed: () => _openForm(null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Tugas', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
