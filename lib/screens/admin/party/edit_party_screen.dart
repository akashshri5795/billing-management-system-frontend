import 'package:flutter/material.dart';
import 'package:rbcledger/model/UserModel.dart';
import 'package:rbcledger/services/user_service.dart';
import 'package:rbcledger/services/party_service.dart';

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
  final openingBalanceController = TextEditingController();

  bool loading = false;
  bool usersLoading = true;
  bool partyLoading = true;

  String type = 'Dr';
  String? nameError;

  List<UserModel> users = [];
  List<int> selectedUserIds = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    nameController.addListener(() {
      if (nameError != null) {
        setState(() {
          nameError = null;
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUsers(),
      _loadParty(),
    ]);
    setState(() => partyLoading = false);
  }

  Future<void> _loadUsers() async {
    final data = await UserService.getUsers();
    users = data.map((e) => UserModel.fromJson(e)).toList();
    setState(() => usersLoading = false);
  }

  Future<void> _loadParty() async {
    final party = await PartyService.getPartyDetail(widget.partyId);

    nameController.text = party['name'] ?? '';
    addressController.text = party['address'] ?? '';
    phoneController.text = party['phone'] ?? '';
    emailController.text = party['email'] ?? '';

    final dr = double.tryParse("${party['opening_balance_dr']}") ?? 0;
    final cr = double.tryParse("${party['opening_balance_cr']}") ?? 0;

    if (dr > 0) {
      type = 'Dr';
      openingBalanceController.text = dr.toString();
    } else {
      type = 'Cr';
      openingBalanceController.text = cr.toString();
    }

    selectedUserIds =
        (party['user_ids'] as List<dynamic>).map((e) => e as int).toList();

    setState(() {}); // Update UI with loaded party info
  }

  /// USER SELECTION DIALOG
  Future<void> _openUserSelectionDialog() async {
    List<int> tempSelected = List.from(selectedUserIds);
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        setDialogState(() {
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
                    setState(() => selectedUserIds = tempSelected);
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

  /// UPDATE PARTY
  Future<void> updateParty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      nameError = null; // Clear previous error
    });

    try {
      await PartyService.updateParty(
        partyId: widget.partyId,
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        type: type,
        openingBalance: openingBalanceController.text.isEmpty
            ? 0
            : double.parse(openingBalanceController.text),
        userIds: selectedUserIds,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (e is Map<String, dynamic>) {
        if (e.containsKey('name')) {
          setState(() {
            nameError = e['name'][0];
          });
          // Trigger validation again to show error
          _formKey.currentState!.validate();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please check your input')),
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
    if (partyLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Party", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _textField(
                "Name",
                nameController,
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
              _textField("Address", addressController),
              _textField("Phone", phoneController, keyboard: TextInputType.phone),
              _textField("Email", emailController),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'Dr', child: Text("Debit")),
                  DropdownMenuItem(value: 'Cr', child: Text("Credit")),
                ],
                onChanged: (v) => setState(() => type = v!),
                decoration: const InputDecoration(
                  labelText: "Type",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _textField(
                "Opening Balance",
                openingBalanceController,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Assign Users",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                subtitle: Text("${selectedUserIds.length} user(s) selected"),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
                onTap: _openUserSelectionDialog,
              ),
              Wrap(
                spacing: 8,
                children: users
                    .where((u) => selectedUserIds.contains(u.id))
                    .map((u) => Chip(label: Text(u.name)))
                    .toList(),
              ),
              const SizedBox(height: 24),
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

  Widget _textField(String label, TextEditingController c,
      {TextInputType keyboard = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}
