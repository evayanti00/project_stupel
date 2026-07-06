import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

class NoteFormScreen extends StatefulWidget {
  final Note? note;
  const NoteFormScreen({super.key, this.note});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isTask = false;
  DateTime? _dueDate;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  bool get _isEdit => widget.note != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titleCtrl.text = widget.note!.title;
      _contentCtrl.text = widget.note!.content;
      _isTask = widget.note!.isTask;
      _dueDate = widget.note!.dueDate;
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Judul tidak boleh kosong');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final note = Note(
        id: widget.note?.id,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        isTask: _isTask,
        isDone: widget.note?.isDone ?? false,
          dueDate: _dueDate,
        createdAt: widget.note?.createdAt ?? DateTime.now(),
      );
      final res = _isEdit
          ? await ApiService.updateNote(note)
          : await ApiService.createNote(note);
      if (res['success'] == true) {
        Navigator.pop(context, true);
      } else {
        setState(() => _error = res['message'] ?? 'Gagal menyimpan');
      }
    } catch (_) {
      setState(() => _error = 'Tidak dapat terhubung ke server');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      final res = await ApiService.deleteNote(widget.note!.id!);
      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        setState(() => _error = res['message'] ?? 'Gagal menghapus');
      }
    } catch (_) {
      setState(() => _error = 'Tidak dapat terhubung ke server');
    } finally {
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Catatan' : 'Catatan Baru'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2))
                : const Text('Simpan',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
          // Type toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.label_outline,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  const Text('Tipe',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: false,
                          icon: Icon(Icons.sticky_note_2_outlined, size: 16),
                          label: Text('Catatan')),
                      ButtonSegment(
                          value: true,
                          icon: Icon(Icons.task_alt_outlined, size: 16),
                          label: Text('Tugas')),
                    ],
                    selected: {_isTask},
                    onSelectionChanged: (s) =>
                        setState(() => _isTask = s.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.primaryLight
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 12),
            if (_isTask)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppColors.textSecondary),
                  title: Text(_dueDate == null ? 'Pilih tanggal deadline' : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                  trailing: TextButton(onPressed: _pickDueDate, child: const Text('Pilih')),
                ),
              ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Judul *'),
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contentCtrl,
            decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                alignLabelWithHint: true),
            maxLines: 8,
          ),
          if (_isEdit) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _deleting ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline),
              label: Text(_deleting ? 'Menghapus...' : 'Hapus Catatan'),
            ),
          ],
        ],
      ),
    );
  }
}
