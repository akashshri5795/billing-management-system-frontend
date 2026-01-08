import 'package:flutter/material.dart';
import 'package:rbcledger/screens/admin/user/add_user_screen.dart';
import 'package:rbcledger/screens/admin/user/user_details_screen.dart';
import 'package:rbcledger/services/user_service.dart';
import '../../../services/auth_service.dart';
import '../../login_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<dynamic>> users;

  @override
  void initState() {
    super.initState();
    users = UserService.getAllUsers();
  }

  void loadUsers() {
    setState(() {
      users = UserService.getAllUsers();
    });
  }

  void logout() async {
    await AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User List",style: TextStyle(color: Colors.white),),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.white),
            tooltip: "Add User",
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddUserScreen()),
              );

              if (added == true) {
                loadUsers();
              }
            },
          ),
          IconButton(onPressed: logout, icon: const Icon(Icons.login_outlined, color: Colors.white), tooltip: "Logout",),
        ],
        backgroundColor: Colors.teal,
      ),

      body: FutureBuilder<List<dynamic>>(
        future: users,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final userList = snapshot.data!;
          return ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              final user = userList[index];
              return ListTile(
                title: Text(user['name']),
                subtitle: Text(user['role'] ?? "", style: TextStyle(color: Colors.teal, fontStyle: FontStyle.italic),),
                trailing: const Icon(Icons.arrow_forward, color: Colors.teal,),
                onTap: () async  {
                  final refreshed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserDetailsScreen(userId: user['id']),
                    ),
                  );
                  if (refreshed == true) {
                    loadUsers();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
