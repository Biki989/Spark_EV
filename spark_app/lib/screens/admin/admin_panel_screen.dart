import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _dashboard = {};
  List<dynamic> _pendingStations = [];
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dashboard = await ApiService.get('/admin/dashboard');
      final stations = await ApiService.get('/admin/stations?status=pending');
      final users = await ApiService.get('/admin/users');
      setState(() {
        _dashboard = dashboard['dashboard'] ?? {};
        _pendingStations = stations['stations'] ?? [];
        _users = users['users'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: SparkTheme.primaryGreen,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Stations'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SparkTheme.primaryGreen))
          : TabBarView(controller: _tabController, children: [
              _buildOverview(),
              _buildStations(),
              _buildUsers(),
            ]),
    );
  }

  Widget _buildOverview() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _AdminStat(label: 'Total Users', value: '${_dashboard['total_users'] ?? 0}', icon: Icons.people),
        _AdminStat(label: 'Total Stations', value: '${_dashboard['total_stations'] ?? 0}', icon: Icons.ev_station),
        _AdminStat(label: 'Pending Stations', value: '${_dashboard['pending_stations'] ?? 0}', icon: Icons.pending),
        _AdminStat(label: 'Total Bookings', value: '${_dashboard['total_bookings'] ?? 0}', icon: Icons.calendar_today),
        _AdminStat(label: 'Total Revenue', value: 'CHF ${_dashboard['total_revenue'] ?? 0}', icon: Icons.attach_money),
      ],
    );
  }

  Widget _buildStations() {
    if (_pendingStations.isEmpty) {
      return Center(child: Text('No pending stations', style: TextStyle(color: Colors.grey[500])));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingStations.length,
      itemBuilder: (context, index) {
        final s = _pendingStations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${s['owner_name']} • ${s['charger_type']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: SparkTheme.primaryGreen),
                  onPressed: () => _verifyStation(s['id'], 'verify'),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: SparkTheme.errorRed),
                  onPressed: () => _verifyStation(s['id'], 'reject'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsers() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final u = _users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: SparkTheme.primaryGreen.withOpacity(0.2),
              child: Text((u['name'] ?? 'U')[0], style: const TextStyle(color: SparkTheme.primaryGreen)),
            ),
            title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('${u['email']} • ${u['role']}'),
            trailing: u['role'] != 'admin' ? IconButton(
              icon: const Icon(Icons.delete_outline, color: SparkTheme.errorRed),
              onPressed: () => _deleteUser(u['id']),
            ) : null,
          ),
        );
      },
    );
  }

  Future<void> _verifyStation(String id, String action) async {
    try {
      await ApiService.post('/admin/stations/$id/verify', body: {'action': action});
      _loadData();
    } catch (e) { /* handle */ }
  }

  Future<void> _deleteUser(String id) async {
    try {
      await ApiService.delete('/admin/users/$id');
      _loadData();
    } catch (e) { /* handle */ }
  }
}

class _AdminStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AdminStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: SparkTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: SparkTheme.primaryGreen),
        ),
        title: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        subtitle: Text(label, style: TextStyle(color: Colors.grey[500])),
      ),
    );
  }
}
