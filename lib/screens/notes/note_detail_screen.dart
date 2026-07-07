import 'package:flutter/material.dart';
import 'dart:convert';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import 'note_form_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late List<_NoteLine> _lines;
  bool _savingChecklist = false;
  late String _currentContent;

  @override
  void initState() {
    super.initState();
    _currentContent = widget.note.content;
    _lines = _parseLines(_currentContent);
  }

  List<_NoteLine> _parseLines(String raw) {
    try {
      final parsed = jsonDecode(raw);
      if (parsed is List) {
        final result = <_NoteLine>[];
        var current = '';

        for (final op in parsed) {
          if (op is! Map) continue;
          final insert = op['insert'];
          final attrs = (op['attributes'] is Map) ? op['attributes'] as Map : const {};
          if (insert is! String) continue;

          final parts = insert.split('\n');
          for (var i = 0; i < parts.length; i++) {
            current += parts[i];

            final isBreak = i < parts.length - 1;
            if (!isBreak) continue;

            final listType = attrs['list']?.toString();
            if (listType == 'checked' || listType == 'unchecked') {
              result.add(_NoteLine(
                text: current.trim(),
                isChecklist: true,
                checked: listType == 'checked',
              ));
            } else {
              result.add(_NoteLine(text: current));
            }
            current = '';
          }
        }

        if (current.trim().isNotEmpty) {
          result.add(_NoteLine(text: current));
        }

        if (result.isNotEmpty) {
          return result;
        }
      }
    } catch (_) {}

    return [
      _NoteLine(text: widget.note.plainContent),
    ];
  }

  String get _title => widget.note.isTask ? 'Detail Tugas' : 'Detail Catatan';

  Future<void> _toggleChecklist(int index, bool checked) async {
    if (_savingChecklist) return;

    final old = _lines[index];
    setState(() {
      _lines[index] = old.copyWith(checked: checked);
      _savingChecklist = true;
    });

    try {
      final updated = Note(
        id: widget.note.id,
        title: widget.note.title,
        content: _buildContentFromLines(_lines),
        isTask: widget.note.isTask,
        isDone: widget.note.isDone,
        dueDate: widget.note.dueDate,
        createdAt: widget.note.createdAt,
        images: widget.note.images,
        priority: widget.note.priority,
        status: widget.note.status,
        description: widget.note.description,
      );

      final res = await ApiService.updateNote(updated);
      if (res['success'] == true) {
        _currentContent = updated.content;
      } else {
        setState(() {
          _lines[index] = old;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message']?.toString() ?? 'Gagal menyimpan checklist')),
          );
        }
      }
    } catch (_) {
      setState(() {
        _lines[index] = old;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan checklist')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingChecklist = false);
      }
    }
  }

  String _buildContentFromLines(List<_NoteLine> lines) {
    final ops = <Map<String, dynamic>>[];
    for (final line in lines) {
      final text = line.text;
      if (text.isNotEmpty) {
        ops.add({'insert': text});
      }

      if (line.isChecklist) {
        ops.add({
          'insert': '\n',
          'attributes': {'list': line.checked ? 'checked' : 'unchecked'}
        });
      } else {
        ops.add({'insert': '\n'});
      }
    }

    if (ops.isEmpty) {
      ops.add({'insert': '\n'});
    }
    return jsonEncode(ops);
  }

  Future<void> _edit(BuildContext context) async {
    final editableNote = Note(
      id: widget.note.id,
      title: widget.note.title,
      content: _currentContent,
      isTask: widget.note.isTask,
      isDone: widget.note.isDone,
      dueDate: widget.note.dueDate,
      createdAt: widget.note.createdAt,
      images: widget.note.images,
      priority: widget.note.priority,
      status: widget.note.status,
      description: widget.note.description,
    );

    final edited = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteFormScreen(note: editableNote, initialIsTask: widget.note.isTask),
      ),
    );

    if (edited == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.note.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _lines.isEmpty
                    ? const Text(
                        '(Tidak ada isi)',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : ListView.separated(
                        itemCount: _lines.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final line = _lines[i];
                          if (!line.isChecklist) {
                            return Text(
                              line.text.trim().isEmpty ? ' ' : line.text,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: AppColors.textPrimary,
                              ),
                            );
                          }

                          return CheckboxListTile(
                            value: line.checked,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primary,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              line.text,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                                decoration: line.checked ? TextDecoration.lineThrough : TextDecoration.none,
                              ),
                            ),
                            onChanged: (v) {
                              if (v == null) return;
                              _toggleChecklist(i, v);
                            },
                          );
                        },
                      ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Edit', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _NoteLine {
  final String text;
  final bool isChecklist;
  final bool checked;

  const _NoteLine({
    required this.text,
    this.isChecklist = false,
    this.checked = false,
  });

  _NoteLine copyWith({String? text, bool? isChecklist, bool? checked}) {
    return _NoteLine(
      text: text ?? this.text,
      isChecklist: isChecklist ?? this.isChecklist,
      checked: checked ?? this.checked,
    );
  }
}
