import 'package:flutter/material.dart';
import 'package:rbcledger/screens/admin/party/edit_party_screen.dart';
import 'package:rbcledger/services/party_service.dart';

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

            final double openingDr =
                double.tryParse("${party['opening_balance_dr']}") ?? 0;
            final double openingCr =
                double.tryParse("${party['opening_balance_cr']}") ?? 0;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text(
                    party['name'] ?? 'Party',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _infoRow("Address", party['address']),
                  _infoRow("Phone", party['phone']),
                  _infoRow("Email", party['email']),
                  const SizedBox(height: 16),

                  /// 🔹 OPENING BALANCE CARDS
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

                  const SizedBox(height: 20),

                  _infoRow(
                    "Tagged Users",
                    (party['tag_users'] as List<dynamic>?)
                        ?.join(", ") ??
                        '-',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🔹 INFO ROW
  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  /// 🔹 BALANCE CARD

  Widget _balanceCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color, // 🔥 SOLID COLOR
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white, // 🔥 FORCE COLOR
                size: 20,
              ),
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

}
