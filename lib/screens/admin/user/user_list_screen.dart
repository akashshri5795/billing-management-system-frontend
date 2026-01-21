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

  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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

  void _searchUser(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _allUsers;
      });
      return;
    }

    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final role = (user['role'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            role.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search user...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _searchUser,
        )
            : const Text(
          "User List",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filteredUsers = _allUsers;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
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
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.login_outlined, color: Colors.white),
            tooltip: "Logout",
          ),
        ],
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

          _allUsers = snapshot.data!;
          _filteredUsers =
          _isSearching ? _filteredUsers : _allUsers;

          final userList =
          _isSearching ? _filteredUsers : _allUsers;

          return ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              final user = userList[index];
              return ListTile(
                title: Text(user['name'] ?? ''),
                subtitle: Text(
                  user['role'] ?? '',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🗑 Delete Button (Hide for admin)
                    if (user['role'] != 'admin')
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: "Delete User",
                        onPressed: () {
                          _deleteUser(user['id'], user['name'] ?? '');
                        },
                      ),

                    // ➡ Details Button
                    const Icon(Icons.arrow_forward, color: Colors.teal),
                  ],
                ),
                onTap: () async {
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

  Future<void> _deleteUser(int userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text("Confirm Delete"),
            content: Text("Are you sure you want to delete '$userName'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await UserService.deleteUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User '$userName' deleted successfully"),
        ),
      );
      loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

