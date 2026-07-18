import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/owner/owner_dashboard_screen.dart';
import '../screens/owner/add_station_screen.dart';
import '../screens/admin/admin_panel_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String ownerDashboard = '/owner-dashboard';
  static const String addStation = '/add-station';
  static const String admin = '/admin';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    home: (_) => const HomeScreen(),
    ownerDashboard: (_) => const OwnerDashboardScreen(),
    addStation: (_) => const AddStationScreen(),
    admin: (_) => const AdminPanelScreen(),
  };
}
