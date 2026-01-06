import 'package:flutter/material.dart';
import 'package:rbcledger/screens/admin/add_user_screen.dart';
import 'package:rbcledger/screens/admin/user_details_screen.dart';
import 'package:rbcledger/services/user_service.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

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
    users = UserService.getUsers();
  }

  void loadUsers() {
    setState(() {
      users = UserService.getUsers();
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
        title: const Text("User List"),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddUserScreen()),
          );
          if(added == true){
            loadUsers();
          }
        },
        child: const Icon(Icons.add),
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
                subtitle: Text(user['email'] ?? ""),
                trailing: const Icon(Icons.arrow_forward),
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
