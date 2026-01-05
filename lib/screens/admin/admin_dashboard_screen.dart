import 'package:flutter/material.dart';
import 'package:myapp/screens/admin/party_list_screen.dart';
import 'package:myapp/screens/admin/user_list_screen.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.extent(
          maxCrossAxisExtent: 220,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _dashboardCard(
              context,
              title: "Users",
              icon: Icons.people,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => UserListScreen()));
              },
            ),
            _dashboardCard(
              context,
              title: "Parties",
              icon: Icons.store,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PartyListScreen()));
              },
            ),
            _dashboardCard(
              context,
              title: "Ledgers",
              icon: Icons.receipt_long,
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => LedgerListScreen()));
              },
            ),
            _dashboardCard(
              context,
              title: "Reports",
              icon: Icons.bar_chart,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}
