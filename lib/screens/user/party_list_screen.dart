import 'package:flutter/material.dart';
import 'package:myapp/screens/user/party_ledger_screen.dart';
import '../../services/user/user_party_service.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  late Future<List<dynamic>> parties;

  @override
  void initState() {
    super.initState();
    parties = UserPartyService.getUserParties();
  }

  void logout() async {
    await AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Party List"),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: parties,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No parties found"));
          }

          final partyList = snapshot.data!;
          return ListView.builder(
            itemCount: partyList.length,
            itemBuilder: (context, index) {
              final party = partyList[index];
              return ListTile(
                title: Text(party['name']),
                subtitle: Text(party['address'] ?? ""),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartyLedgerScreen(partyId: party['party_id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
