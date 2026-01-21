import 'package:flutter/material.dart';
import 'package:rbcledger/screens/admin/party/add_party_screen.dart';
import 'package:rbcledger/screens/admin/ledger/view_ledger_screen.dart';
import 'package:rbcledger/screens/admin/party/party_details_screen.dart';
import '../../../services/party_service.dart';

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  List<dynamic> partyList = [];
  List<dynamic> filteredList = [];
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
      setState(() {
        partyList = data;
        filteredList = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> deleteParty(int partyId, String partyName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete '$partyName'?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => loading = true);

    try {
      final success = await PartyService.deleteParty(partyId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Party deleted successfully')),
        );
        await loadParties();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete party')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Parties",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: PartySearchDelegate(partyList),
              );
              if (result != null) {
                setState(() => filteredList = result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.white),
            onPressed: () async {
              final added = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPartyScreen()),
              );
              if (added == true) {
                loadParties();
              }
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : filteredList.isEmpty
          ? const Center(child: Text("No parties found"))
          : ListView.builder(
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final party = filteredList[index];
          return ListTile(
            title: Text(
              party['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              party['address'] ?? "",
              style: const TextStyle(
                color: Colors.teal,
                fontStyle: FontStyle.italic,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.leaderboard,
                    color: Colors.blueGrey,
                  ),
                  tooltip: "View Ledger",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewLedgerScreen(
                          partyId: party['party_id'],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.teal,
                  ),
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

                // Delete Button
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  tooltip: "Delete Party",
                  onPressed: () {
                    deleteParty(party['party_id'], party['name']);
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

class PartySearchDelegate extends SearchDelegate<List<dynamic>> {
  final List<dynamic> parties;

  PartySearchDelegate(this.parties);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, parties),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = parties.where((party) {
      return party['name']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();

    return _buildList(results, context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = parties.where((party) {
      return party['name']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();

    return _buildList(suggestions, context);
  }

  Widget _buildList(List<dynamic> list, BuildContext context) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final party = list[index];
        return ListTile(
          title: Text(party['name']),
          subtitle: Text(party['address'] ?? ''),
          onTap: () => close(context, list),
        );
      },
    );
  }
}
