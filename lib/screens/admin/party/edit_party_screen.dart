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
  final openingBalanceController = TextEditingController();

  bool loading = false;
  bool usersLoading = true;
  bool partyLoading = true;

  String type = 'Dr';

  List<UserModel> users = [];
  List<int> selectedUserIds = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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
    usersLoading = false;
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
                      onChanged: (checked) {
                        setDialogState(() {
                          checked == true
                              ? tempSelected.add(user.id)
                              : tempSelected.remove(user.id);
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

    setState(() => loading = true);

    try {
      await PartyService.updateParty(
        partyId: widget.partyId,
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        type: type,
        openingBalance: openingBalanceController.text.isEmpty
            ? 0
            : double.parse(openingBalanceController.text),
        userIds: selectedUserIds,
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
      appBar: AppBar(title: const Text("Edit Party")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _textField("Name", nameController),
              _textField("Address", addressController),
              _textField("Phone", phoneController,
                  keyboard: TextInputType.phone),
              _textField("Email (optional)", emailController),

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
                keyboard:
                const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 16),

              ListTile(
                title: const Text("Assign Users",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    "${selectedUserIds.length} user(s) selected"),
                trailing: const Icon(Icons.arrow_forward_ios),
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
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) =>
        v == null || v.isEmpty ? "$label required" : null,
      ),
    );
  }
}
