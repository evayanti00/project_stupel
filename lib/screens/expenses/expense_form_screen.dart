import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;
  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = Expense.categories.first;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _descCtrl.text = widget.expense!.description;
      _amountCtrl.text = widget.expense!.amount.toInt().toString();
      _category = widget.expense!.category;
      _date = widget.expense!.date;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_descCtrl.text.trim().isEmpty || _amountCtrl.text.isEmpty) {
      setState(() => _error = 'Deskripsi dan nominal harus diisi');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Nominal tidak valid');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final expense = Expense(
        id: widget.expense?.id,
        description: _descCtrl.text.trim(),
        amount: amount,
        category: _category,
        date: _date,
      );
      final res = _isEdit
          ? await ApiService.updateExpense(expense)
          : await ApiService.createExpense(expense);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Pengeluaran' : 'Pengeluaran Baru'),
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
          TextFormField(
            controller: _descCtrl,
            decoration:
                const InputDecoration(labelText: 'Deskripsi *'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Nominal (Rp) *',
                prefixText: 'Rp '),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            decoration:
                const InputDecoration(labelText: 'Kategori'),
            items: Expense.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon:
                      Icon(Icons.calendar_today, size: 18)),
              child: Text(
                DateFormat('d MMMM yyyy', 'id').format(_date),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
