import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  Map<String, dynamic> _dashboard = {};
  List<dynamic> _dailyEarnings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final response = await ApiService.get('/stations/owner/dashboard');
      setState(() {
        _dashboard = response['dashboard'] ?? {};
        _dailyEarnings = response['daily_earnings'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Dashboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SparkTheme.primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Stats grid
                  Row(
                    children: [
                      _StatCard(label: 'Total Stations', value: '${_dashboard['total_stations'] ?? 0}', icon: Icons.ev_station, color: SparkTheme.primaryGreen),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Active Bookings', value: '${_dashboard['active_bookings'] ?? 0}', icon: Icons.calendar_today, color: SparkTheme.infoBlue),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(label: "Today's Earnings", value: 'CHF ${_dashboard['today_earnings'] ?? '0'}', icon: Icons.attach_money, color: SparkTheme.warningYellow),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Total Earnings', value: 'CHF ${_dashboard['total_earnings'] ?? '0'}', icon: Icons.account_balance_wallet, color: Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Earnings chart placeholder
                  const Text('Weekly Earnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: SparkTheme.grey100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _dailyEarnings.isEmpty
                        ? Center(child: Text('No earnings data', style: TextStyle(color: Colors.grey[500])))
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _dailyEarnings.map<Widget>((d) {
                                final earnings = double.tryParse(d['earnings'].toString()) ?? 0;
                                final maxE = _dailyEarnings.fold<double>(1, (m, e) => (double.tryParse(e['earnings'].toString()) ?? 0) > m ? double.tryParse(e['earnings'].toString()) ?? 0 : m);
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          height: (earnings / maxE) * 120,
                                          decoration: BoxDecoration(
                                            color: SparkTheme.primaryGreen,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(d['date']?.toString().substring(5) ?? '', style: const TextStyle(fontSize: 9)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Quick actions
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/add-station'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Station'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
