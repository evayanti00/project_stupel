import 'package:flutter/material.dart';
import '../task/task_screen.dart';
import '../expense/expense_screen.dart';
import '../profile/profile_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // dummy data
  List<String> notes = ["Catatan 1", "Catatan 2"];
  List<String> tasks = ["Tugas A", "Tugas B", "Tugas C", "Tugas D", "Tugas E"];
  List<String> expenses = ["Makan Rp20.000", "Transport Rp50.000"];

  String? selectedBox; // box yang diklik

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      selectedBox = null; // reset ke ringkasan kalau pindah tab
    });
  }

  // Ringkasan Dashboard
  Widget _buildDashboardSummary() {
    if (selectedBox == null) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedBox = "Tugas"),
                  child: Card(
                    color: Colors.blue[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.task, size: 40),
                          Text("Tugas Belum Selesai: ${tasks.length}"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedBox = "Pengeluaran"),
                  child: Card(
                    color: Colors.green[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.money, size: 40),
                          Text("Total Pengeluaran: ${expenses.length} item"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => selectedBox = "Catatan"),
            child: Card(
              color: Colors.orange[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.note, size: 40),
                    Text("Jumlah Catatan: ${notes.length}"),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Detail daftar sesuai box yang diklik
      final items = selectedBox == "Tugas"
          ? tasks
          : selectedBox == "Pengeluaran"
              ? expenses
              : notes;

      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(title: Text(items[index])),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => setState(() => selectedBox = null),
            child: const Text("Kembali ke Dashboard"),
          )
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardSummary(), // index 0 → Dashboard
      const TaskScreen(),       // index 1 → CRUD Tugas
      const ExpenseScreen(),    // index 2 → CRUD Pengeluaran
      const ProfileScreen(),    // index 3 → Profil
    ];

    final List<String> titles = [
      "Dashboard",
      "Tugas",
      "Pengeluaran",
      "Profil",
    ];

    return WillPopScope(
      onWillPop: () async {
        if (selectedBox != null) {
          setState(() {
            selectedBox = null; // back → kembali ke ringkasan Dashboard
          });
          return false; // jangan keluar app
        }
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0; // back → kembali ke Dashboard
          });
          return false;
        }
        return true; // kalau sudah di Dashboard ringkasan → baru keluar app
      },
      child: Scaffold(
        appBar: AppBar(title: Text(titles[_selectedIndex])),
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tugas"),
            BottomNavigationBarItem(icon: Icon(Icons.money), label: "Pengeluaran"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
          ],
        ),
      ),
    );
  }
}