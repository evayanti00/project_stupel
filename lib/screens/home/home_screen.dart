import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';
import 'dashboard_tab.dart';
import '../notes/notes_tab.dart';
import '../notes/tasks_tab.dart';
import '../expenses/expenses_tab.dart';
import '../admin/admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  final ValueNotifier<int> _dashboardRefreshTrigger = ValueNotifier<int>(0);

  late final List<Widget> _tabs = [
    DashboardTab(refreshTrigger: _dashboardRefreshTrigger),
    const TasksTab(),
    NotesTab(),
    ExpensesTab(onExpenseChanged: () => _dashboardRefreshTrigger.value++),
    const ProfileScreen(embedded: true),
  ];

  static const _titles = ['Home', 'Tasks', 'Notes', 'Expenses', 'Profile'];

  void _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text('STUPEL • ${_titles[_idx]}'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cari',
            onPressed: () {
              showSearch(context: context, delegate: _GlobalSearchDelegate());
            },
            icon: const Icon(Icons.search),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'logout') _logout();
                if (v == 'admin') Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(user?.name ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                const PopupMenuDivider(),
                if (user?.role == 'admin')
                  const PopupMenuItem(
                    value: 'admin',
                    child: Row(
                      children: [
                        Icon(Icons.security, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Admin Panel'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Keluar',
                          style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  (user?.name ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _idx, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task_rounded, color: AppColors.primary),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon:
                Icon(Icons.sticky_note_2_rounded, color: AppColors.primary),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.primary),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _GlobalSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Cari notes atau tasks';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _SearchResults(query: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _SearchResults(query: query);
  }
}

class _SearchResults extends StatelessWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Note>>(
      future: ApiService.getNotes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final key = query.trim().toLowerCase();
        final filtered = snapshot.data!
            .where(
              (n) => key.isEmpty || n.title.toLowerCase().contains(key) || n.plainContent.toLowerCase().contains(key),
            )
            .toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('Tidak ada hasil pencarian'));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final item = filtered[i];
            return ListTile(
              leading: Icon(item.isTask ? Icons.task_alt : Icons.sticky_note_2_outlined),
              title: Text(item.title),
              subtitle: Text(
                item.plainContent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Chip(
                label: Text(item.isTask ? 'Task' : 'Note'),
              ),
            );
          },
        );
      },
    );
  }
}
