import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: SparkTheme.primaryGreen.withOpacity(0.2),
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: SparkTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
              Center(child: Text(user.email, style: TextStyle(color: Colors.grey[500]))),
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: SparkTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SparkTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Menu items
              if (user.isOwner) ...[
                _MenuItem(icon: Icons.dashboard, label: 'Owner Dashboard', onTap: () => Navigator.pushNamed(context, '/owner-dashboard')),
                _MenuItem(icon: Icons.add_business, label: 'Add Station', onTap: () => Navigator.pushNamed(context, '/add-station')),
              ],
              if (user.isAdmin) ...[
                _MenuItem(icon: Icons.admin_panel_settings, label: 'Admin Panel', onTap: () => Navigator.pushNamed(context, '/admin')),
              ],
              _MenuItem(icon: Icons.payment, label: 'Payment History', onTap: () {}),
              _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
              _MenuItem(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
              _MenuItem(icon: Icons.info_outline, label: 'About Spark', onTap: () {}),
              const SizedBox(height: 16),
              _MenuItem(
                icon: Icons.logout,
                label: 'Sign Out',
                color: SparkTheme.errorRed,
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? SparkTheme.grey800;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: c)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
