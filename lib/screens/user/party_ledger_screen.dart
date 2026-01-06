import 'package:flutter/material.dart';
import 'package:rbcledger/services/user/user_party_service.dart';

class PartyLedgerScreen extends StatelessWidget {
  final int partyId;

  const PartyLedgerScreen({super.key, required this.partyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Party Ledger"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: UserPartyService.getUserPartyLedgerDetail(partyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No ledger data found"));
          }

          final ledgerList = snapshot.data!;

          // Party Name (from first ledger entry)
          final partyName =
          ledgerList.isNotEmpty ? ledgerList[0]['name'] ?? 'Party' : 'Party';

          // Calculate totals
          double totalDebit = 0;
          double totalCredit = 0;
          for (var l in ledgerList) {
            totalDebit += double.tryParse(l['debit']?.toString() ?? '0') ?? 0;
            totalCredit += double.tryParse(l['credit']?.toString() ?? '0') ?? 0;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Party Name
                Text(
                  partyName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Ledger Table
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade200,
                      ),
                      columns: const [
                        DataColumn(label: Text('Entry Date')),
                        DataColumn(label: Text('Voucher No')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Debit')),
                        DataColumn(label: Text('Credit')),
                      ],
                      rows: [
                        ...ledgerList.map<DataRow>((ledger) {
                          return DataRow(cells: [
                            DataCell(Text(ledger['entry_date'] ?? '-')),
                            DataCell(Text(ledger['voucher_no'] ?? '-')),
                            DataCell(Text(ledger['type'] ?? '-')),
                            DataCell(Text(
                                (double.tryParse(ledger['debit']?.toString() ?? '0') ?? 0)
                                    .toStringAsFixed(2))),
                            DataCell(Text(
                                (double.tryParse(ledger['credit']?.toString() ?? '0') ?? 0)
                                    .toStringAsFixed(2))),
                          ]);
                        }).toList(),
                        // Total row
                        DataRow(
                          color: MaterialStateProperty.all(Colors.grey.shade300),
                          cells: [
                            const DataCell(Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                            const DataCell(Text('')),
                            DataCell(Text(
                              totalDebit.toStringAsFixed(2),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                            DataCell(Text(
                              totalCredit.toStringAsFixed(2),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
