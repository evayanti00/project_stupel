import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

class NoteFormScreen extends StatefulWidget {
  final Note? note;
  final bool initialIsTask;
  const NoteFormScreen({super.key, this.note, this.initialIsTask = false});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  late QuillController _quillController;
  bool _isTask = false;
  DateTime? _dueDate;
  bool _saving = false;
  bool _deleting = false;
  String? _error;
  final List<String> _images = [];
  String _priority = 'Sedang';
  String _status = 'Belum Dimulai';

  bool get _isEdit => widget.note != null;
  String get _entityName => _isTask ? 'Tugas' : 'Catatan';

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    _isTask = widget.initialIsTask;
    if (_isEdit) {
      _titleCtrl.text = widget.note!.title;
      _contentCtrl.text = widget.note!.content;
      _isTask = widget.note!.isTask;
      _dueDate = widget.note!.dueDate;
      _images.addAll(widget.note!.images);
      _priority = widget.note!.priority ?? _priority;
      _status = widget.note!.status ?? _status;
      try {
        final data = jsonDecode(widget.note!.content);
        final doc = Document.fromJson(data is List ? data : []);
        _quillController = QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
      } catch (_) {
        _quillController.document = Document()..insert(0, widget.note!.content);
      }
      _syncImagesIntoDocument();
    }
  }

  void _insertImageIntoEditor(String path) {
    final selection = _quillController.selection;
    final index = selection.baseOffset >= 0
        ? selection.baseOffset
        : _quillController.document.length - 1;
    _quillController.replaceText(
      index,
      0,
      BlockEmbed.image(path),
      TextSelection.collapsed(offset: index + 1),
    );
    _quillController.replaceText(index + 1, 0, '\n', TextSelection.collapsed(offset: index + 2));
  }

  void _syncImagesIntoDocument() {
    final existing = <String>{};
    for (final op in _quillController.document.toDelta().toJson().cast<Map<String, dynamic>>()) {
      final insert = op['insert'];
      if (insert is Map && insert['image'] is String) {
        existing.add(insert['image'].toString());
      }
    }
    for (final imagePath in _images) {
      if (!existing.contains(imagePath)) {
        _insertImageIntoEditor(imagePath);
      }
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
      final contentJson = jsonEncode(_quillController.document.toDelta().toJson());
      final note = Note(
        id: widget.note?.id,
        title: _titleCtrl.text.trim(),
        content: contentJson,
        isTask: _isTask,
        isDone: widget.note?.isDone ?? false,
        dueDate: _dueDate,
        createdAt: widget.note?.createdAt ?? DateTime.now(),
        images: _images,
        priority: _isTask ? _priority : null,
        status: _isTask ? _status : null,
        description: _titleCtrl.text.trim(),
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
        title: Text('Hapus $_entityName'),
        content: Text('Apakah Anda yakin ingin menghapus ${_entityName.toLowerCase()} ini?'),
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
        title: Text(_isEdit ? 'Edit $_entityName' : '$_entityName Baru'),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          if (_isTask) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prioritas', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      items: ['Rendah', 'Sedang', 'Tinggi'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _priority = v ?? 'Sedang'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _status,
                      items: ['Belum Dimulai', 'Sedang Dikerjakan', 'Selesai'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _status = v ?? 'Belum Dimulai'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SizedBox(
                      height: 56,
                      child: QuillSimpleToolbar(
                        controller: _quillController,
                        config: const QuillSimpleToolbarConfig(
                          showAlignmentButtons: true,
                          showColorButton: true,
                          showBackgroundColorButton: true,
                          showQuote: true,
                          showSubscript: false,
                          showSuperscript: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: QuillEditor.basic(
                        controller: _quillController,
                        config: QuillEditorConfig(
                          embedBuilders: const [_NoteImageEmbedBuilder()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
              label: Text(_deleting ? 'Menghapus...' : 'Hapus $_entityName'),
            ),
          ],
        ],
      ),
    );
  }

}

class _NoteImageEmbedBuilder extends EmbedBuilder {
  const _NoteImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final imagePath = embedContext.node.value.data.toString();
    final uri = Uri.tryParse(imagePath);
    final isNetwork = uri != null &&
        (uri.scheme.toLowerCase() == 'http' || uri.scheme.toLowerCase() == 'https');

    final image = isNetwork
        ? Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
          )
        : Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 220,
          height: 140,
          color: const Color(0xFFF3F4F6),
          child: image,
        ),
      ),
    );
  }
}
