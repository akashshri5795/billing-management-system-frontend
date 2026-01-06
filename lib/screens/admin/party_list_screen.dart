import 'package:flutter/material.dart';
import 'package:rbcledger/screens/admin/add_party_screen.dart';
import 'package:rbcledger/screens/admin/ledger/add_ledger_screen.dart';
import 'package:rbcledger/screens/admin/ledger/view_ledger_screen.dart';
import 'package:rbcledger/screens/admin/party_details_screen.dart';
import '../../services/party_service.dart';

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  List<dynamic> partyList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadParties();
  }

  Future<void> loadParties() async {
    setState(() => loading = true);
    try {
      final data = await PartyService.getParties();
      setState(() => partyList = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parties")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPartyScreen()),
          );

          if (added == true) {
            loadParties();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : partyList.isEmpty
          ? const Center(child: Text("No parties found"))
          : ListView.builder(
        itemCount: partyList.length,
        itemBuilder: (context, index) {
          final party = partyList[index];

          return ListTile(
            title: Text(party['name']),
            subtitle: Text(party['address'] ?? ""),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 📘 Ledger Button
                IconButton(
                  icon: const Icon(Icons.leaderboard),
                  tooltip: "View Ledger Entry",
                  onPressed: () async {
                    final added = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewLedgerScreen(
                          partyId: party['party_id'],
                        ),
                      ),
                    );

                    if (added == true) {
                      loadParties();
                    }
                  },
                ),

                // ➡ Party Details Button
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  tooltip: "View Party Details",
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PartyDetailsScreen(
                          partyId: party['party_id'],
                        ),
                      ),
                    );

                    if (updated == true) {
                      loadParties();
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
