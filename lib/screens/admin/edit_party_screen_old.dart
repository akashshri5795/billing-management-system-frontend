import 'package:flutter/material.dart';
import 'package:myapp/model/UserModel.dart';
import 'package:myapp/services/user_service.dart';
import 'package:myapp/services/party_service.dart';

class EditPartyScreen extends StatefulWidget {
  final int partyId;

  const EditPartyScreen({super.key, required this.partyId});

  @override
  State<EditPartyScreen> createState() => _EditPartyScreenState();
}

class _EditPartyScreenState extends State<EditPartyScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final openingBalanceDrController = TextEditingController();
  final openingBalanceCrController = TextEditingController();

  bool loading = false;
  bool usersLoading = true;

  List<UserModel> users = [];
  List<int> selectedUserIds = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadPartyDetails();
  }

  /// Load all users for checkbox selection
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

  /// Load existing party details and prefill form
  Future<void> loadPartyDetails() async {
    setState(() => loading = true);
    try {
      final data = await PartyService.getPartyDetail(widget.partyId);

      nameController.text = data['name'] ?? '';
      addressController.text = data['address'] ?? '';
      phoneController.text = data['phone'] ?? '';
      emailController.text = data['email'] ?? '';
      openingBalanceDrController.text = (data['opening_balance_dr'] ?? 0).toString();
      openingBalanceCrController.text = (data['opening_balance_cr'] ?? 0).toString();

      // ✅ Preselect users
      if (data['user_ids'] != null) {
        selectedUserIds = List<int>.from(data['user_ids']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load party: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  /// Open user selection popup
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

  /// Update party API call
  Future<void> updateParty() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one user")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await PartyService.updateParty(
        partyId: widget.partyId,
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        openingBalanceDr: openingBalanceDrController.text.isEmpty ? 0.0 : double.parse(openingBalanceDrController.text),
        openingBalanceCr: openingBalanceCrController.text.isEmpty ? 0.0 : double.parse(openingBalanceCrController.text),
        userIds: selectedUserIds,
      );

      // Success → close screen and notify PartyListScreen
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Update failed: $e")));
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
    openingBalanceDrController.dispose();
    openingBalanceCrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Party")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Name required" : null,
              ),
              const SizedBox(height: 12),

              // Address
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Address required" : null,
              ),
              const SizedBox(height: 12),

              // Phone
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Phone required" : null,
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Opening Balance
              TextFormField(
                controller: openingBalanceDrController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(
                  labelText: "Opening Balance",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Assign Users
              ListTile(
                title: const Text(
                  "Assign Users",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  selectedUserIds.isEmpty
                      ? "No users selected"
                      : "${selectedUserIds.length} user(s) selected",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _openUserSelectionDialog,
              ),

              // Chips
              if (selectedUserIds.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: users
                      .where((u) => selectedUserIds.contains(u.id))
                      .map((u) => Chip(label: Text(u.name)))
                      .toList(),
                ),

              const SizedBox(height: 20),

              // Update button
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: updateParty,
                child: const Text("Update Party"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
