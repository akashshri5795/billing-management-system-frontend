import 'package:flutter/material.dart';
import 'package:myapp/screens/admin/party/edit_party_screen.dart';
import 'package:myapp/services/party_service.dart';

class PartyDetailsScreen extends StatefulWidget {
  final int partyId;
  const PartyDetailsScreen({super.key, required this.partyId});

  @override
  State<PartyDetailsScreen> createState() => _PartyDetailsScreenState();
}

class _PartyDetailsScreenState extends State<PartyDetailsScreen> {
  late Future<Map<String, dynamic>> partyFuture;
  bool updated = false;

  @override
  void initState() {
    super.initState();
    _loadParty();
  }

  void _loadParty() {
    partyFuture = PartyService.getPartyDetail(widget.partyId);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, updated ? true : null);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Party Details"),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditPartyScreen(partyId: widget.partyId),
                  ),
                );

                if (result == true) {
                  setState(() {
                    _loadParty();
                    updated = true;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Party updated successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: partyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text("No party data"));
            }

            final party = snapshot.data!;

            final openingDr =
                double.tryParse("${party['opening_balance_dr']}") ?? 0;
            final openingCr =
                double.tryParse("${party['opening_balance_cr']}") ?? 0;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                /// PARTY NAME
                Text(
                  party['name'] ?? 'Party',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),

                _infoRow(Icons.location_on, "Address", party['address']),
                _infoRow(Icons.phone, "Phone", party['phone']),
                _infoRow(Icons.email, "Email", party['email']),

                const SizedBox(height: 20),

                /// OPENING BALANCE
                Row(
                  children: [
                    Expanded(
                      child: _balanceCard(
                        title: "Opening Debit",
                        amount: openingDr,
                        color: Colors.green,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _balanceCard(
                        title: "Opening Credit",
                        amount: openingCr,
                        color: Colors.red,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// TAGGED USERS
                const Text(
                  "Tagged Users",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _taggedUsersChips(party['tag_users'] as List<dynamic>?),
              ],
            );
          },
        ),
      ),
    );
  }

  /// INFO ROW WITH ICON
  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value?.toString() ?? "-")),
        ],
      ),
    );
  }

  /// OPENING BALANCE CARD
  Widget _balanceCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// TAGGED USERS CHIPS
  Widget _taggedUsersChips(List<dynamic>? users) {
    if (users == null || users.isEmpty) {
      return const Text("-");
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: users.map((u) {
        return Chip(
          label: Text(
            u.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}
