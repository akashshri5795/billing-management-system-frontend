import 'package:flutter/material.dart';
import 'package:rbcledger/screens/user/view_ledger_screen.dart';
import 'package:rbcledger/screens/user/user_party_details_screen.dart';
import '../../services/party_service.dart';

class UserPartyListScreen extends StatefulWidget {
  const UserPartyListScreen({super.key});

  @override
  State<UserPartyListScreen> createState() => _UserPartyListScreenState();
}

class _UserPartyListScreenState extends State<UserPartyListScreen> {
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
      final data = await PartyService.getUserPartyList();
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
      appBar: AppBar(title: const Text("Parties",
        style: TextStyle(color: Colors.white),
      ),backgroundColor: Colors.teal),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : partyList.isEmpty
          ? const Center(child: Text("No parties found"))
          : ListView.builder(
        itemCount: partyList.length,
        itemBuilder: (context, index) {
          final party = partyList[index];

          return ListTile(
            title: Text(party['name'], style: TextStyle(color: Colors.grey.shade800),),
            subtitle: Text(party['address'] ?? "", style: TextStyle(color: Colors.teal.shade600, fontStyle: FontStyle.italic),),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 📘 Ledger Button
                IconButton(
                  icon: const Icon(Icons.leaderboard, color:Colors.blueGrey),
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
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.teal,),
                  tooltip: "View Party Details",
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserPartyDetailsScreen(
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
