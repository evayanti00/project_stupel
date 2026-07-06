import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import 'expense_form_screen.dart';

class ExpensesTab extends StatefulWidget {
  final VoidCallback? onExpenseChanged;

  const ExpensesTab({super.key, this.onExpenseChanged});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  List<Expense> _expenses = [];
  bool _loading = true;
  double _balance = 0;

  final _currencyFmt = NumberFormat.currency(
      locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _balance = 0;
    });
    try {
      final result = await ApiService.getExpensesWithBalance();
      _expenses = result['expenses'] as List<Expense>;
      _balance = result['balance'] as double;
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(Expense e) async {
    await ApiService.deleteExpense(e.id!);
    widget.onExpenseChanged?.call();
    _load();
  }

  Future<void> _showBalanceDialog(String operation) async {
    final amountCtrl = TextEditingController();
    bool saving = false;
    String? error;

    final actionLabel = operation == 'add' ? 'Tambah' : 'Kurangi';
    final titleLabel = operation == 'add' ? 'Tambah Saldo' : 'Kurangi Saldo';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(titleLabel),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(error!, style: const TextStyle(color: AppColors.danger)),
                ),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '$actionLabel Saldo (Rp)',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final value = double.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9\.]'), ''));
                      if (value == null || value <= 0) {
                        setDialogState(() => error = 'Nominal harus lebih besar dari 0');
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        final res = await ApiService.topUpBalance(value, operation: operation);
                        if (res['success'] == true) {
                          Navigator.pop(context, true);
                        } else {
                          setDialogState(() => error = res['message'] ?? 'Gagal memperbarui saldo');
                        }
                      } catch (_) {
                        setDialogState(() => error = 'Tidak dapat terhubung ke server');
                      } finally {
                        setDialogState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(actionLabel),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      widget.onExpenseChanged?.call();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saldo berhasil ${operation == 'add' ? 'ditambah' : 'dikurangi'}'), backgroundColor: AppColors.success),
      );
    }
  }

  double get _total => _expenses.fold(0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Saldo',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _showBalanceDialog('add'),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.white24),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _showBalanceDialog('subtract'),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.white24),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.remove, size: 16),
                                      label: const Text('Kurangi', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_currencyFmt.format(_balance),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            const Text('Total Pengeluaran',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(_currencyFmt.format(_total),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text('${_expenses.length} transaksi tercatat',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Riwayat Pengeluaran',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (_expenses.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Belum ada pengeluaran',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final e = _expenses[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Slidable(
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) => _openForm(e),
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      icon: Icons.edit,
                                      label: 'Edit',
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                              left: Radius.circular(12)),
                                    ),
                                    SlidableAction(
                                      onPressed: (_) => _delete(e),
                                      backgroundColor: AppColors.danger,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                      label: 'Hapus',
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                              right: Radius.circular(12)),
                                    ),
                                  ],
                                ),
                                child: Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                          Icons.receipt_outlined,
                                          color: AppColors.success,
                                          size: 20),
                                    ),
                                    title: Text(e.description,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.primaryLight,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(e.category,
                                              style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 11)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('d MMM yyyy', 'id')
                                              .format(e.date),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                      _currencyFmt.format(e.amount),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppColors.danger),
                                    ),
                                    onTap: () => _openForm(e),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _expenses.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(null),
        backgroundColor: AppColors.success,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _openForm(Expense? expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ExpenseFormScreen(expense: expense)),
    );
    if (result == true) {
      widget.onExpenseChanged?.call();
      _load();
    }
  }
}
