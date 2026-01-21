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
  List<dynamic> _allParties = [];
  List<dynamic> _filteredParties = [];

  bool loading = true;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadParties();
  }

  Future<void> loadParties() async {
    setState(() => loading = true);
    try {
      final data = await PartyService.getUserPartyList();
      setState(() {
        _allParties = data;
        _filteredParties = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void _searchParty(String query) {
    if (query.isEmpty) {
      setState(() => _filteredParties = _allParties);
      return;
    }

    setState(() {
      _filteredParties = _allParties.where((party) {
        final name = (party['name'] ?? '').toString().toLowerCase();
        final address = (party['address'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            address.contains(query.toLowerCase());
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
            hintText: 'Search party...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _searchParty,
        )
            : const Text(
          "Parties",
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
                  _filteredParties = _allParties;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _filteredParties.isEmpty
          ? const Center(child: Text("No parties found"))
          : ListView.builder(
        itemCount: _filteredParties.length,
        itemBuilder: (context, index) {
          final party = _filteredParties[index];

          return ListTile(
            title: Text(
              party['name'] ?? '',
              style:
              TextStyle(color: Colors.grey.shade800),
            ),
            subtitle: Text(
              party['address'] ?? '',
              style: TextStyle(
                color: Colors.teal.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 📘 Ledger Button
                IconButton(
                  icon: const Icon(
                    Icons.leaderboard,
                    color: Colors.blueGrey,
                  ),
                  tooltip: "View Ledger Entry",
                  onPressed: () async {
                    final added =
                    await Navigator.push<bool>(
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
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.teal,
                  ),
                  tooltip: "View Party Details",
                  onPressed: () async {
                    final updated =
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UserPartyDetailsScreen(
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
