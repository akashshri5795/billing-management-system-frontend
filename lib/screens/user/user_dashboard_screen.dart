import 'package:flutter/material.dart';
import 'package:rbcledger/screens/user/user_party_list_screen.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Dashboard",
          style: TextStyle(
            color: Colors.white,
          ),),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Log out",
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
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child:Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 250,
            height: 180,
            child: _dashboardCard(
              context,
              title: "Parties",
              icon: Icons.store,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => UserPartyListScreen()));
              },
            )
          ),
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
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color:Colors.teal),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: Colors.grey
              ),
            )
          ],
        ),
      ),
    );
  }
}
