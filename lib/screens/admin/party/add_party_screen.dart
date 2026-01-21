import 'package:flutter/material.dart';
import 'package:rbcledger/model/UserModel.dart';
import 'package:rbcledger/services/user_service.dart';
import 'package:rbcledger/services/party_service.dart';

class AddPartyScreen extends StatefulWidget {
  const AddPartyScreen({super.key});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final openingBalanceController = TextEditingController();

  bool loading = false;
  bool usersLoading = true;
  String type = 'Dr';
  String? nameError;


  List<UserModel> users = [];
  List<int> selectedUserIds = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
    nameController.addListener(() {
      if (nameError != null) {
        setState(() {
          nameError = null;
        });
      }
    });
  }

  Future<void> loadUsers() async {
    try {
      final data = await UserService.getUsers();
      users = data.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => usersLoading = false);
    }
  }

  /// 🔹 USER SELECTION POPUP
  Future<void> _openUserSelectionDialog() async {
    List<int> tempSelected = List.from(selectedUserIds);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Users"),
              content: SizedBox(
                width: double.maxFinite,
                child: usersLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                  shrinkWrap: true,
                  children: users.map((user) {
                    return CheckboxListTile(
                      value: tempSelected.contains(user.id),
                      title: Text(user.name),
                      subtitle: Text(user.role),
                      onChanged: (checked) {
                        setStateDialog(() {
                          if (checked == true) {
                            tempSelected.add(user.id);
                          } else {
                            tempSelected.remove(user.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedUserIds = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  /// 🔹 SAVE PARTY
  Future<void> saveParty() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one user")),
      );
      return;
    }

    setState(() {
      loading = true;
      nameError = null;
    });

    try {
      await PartyService.createParty(
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        type: type,
        openingBalance: openingBalanceController.text.isEmpty ? 0.0 : double.parse(openingBalanceController.text),
        userIds: selectedUserIds,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (e is Map<String, dynamic>) {
        if (e.containsKey('name')) {
          setState(() {
            nameError = e['name'][0];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please check your input')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }


  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    openingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Party", style: TextStyle(color: Colors.white),),backgroundColor: Colors.teal,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// NAME
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Name required";
                  }
                  if (nameError != null) {
                    return nameError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              /// ADDRESS
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Address required" : null,
              ),
              const SizedBox(height: 12),

              /// PHONE
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              /// EMAIL
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(
                      value: 'Dr', child: Text("Debit")),
                  DropdownMenuItem(
                      value: 'Cr', child: Text("Credit")),
                ],
                onChanged: (v) =>
                    setState(() => type = v!),
                decoration:
                const InputDecoration(
                  labelText: "Type",
                  border: OutlineInputBorder(),),
              ),
              const SizedBox(height: 12),

              /// OPENING BALANCE
              TextFormField(
                controller: openingBalanceController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Opening Balance",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Amount required" : null,
              ),
              const SizedBox(height: 16),

              /// ASSIGN USERS
              ListTile(
                title: const Text(
                  "Assign Users",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                subtitle: Text(
                  selectedUserIds.isEmpty
                      ? "No users selected"
                      : "${selectedUserIds.length} user(s) selected",
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal,),
                onTap: _openUserSelectionDialog,
              ),

              /// SELECTED USER CHIPS
              if (selectedUserIds.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: users
                      .where((u) => selectedUserIds.contains(u.id))
                      .map((u) => Chip(label: Text(u.name)))
                      .toList(),
                ),

              const SizedBox(height: 20),

              /// SAVE BUTTON
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: saveParty,
                child: const Text("Save Party"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
