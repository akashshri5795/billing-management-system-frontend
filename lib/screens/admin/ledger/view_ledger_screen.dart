import 'package:flutter/material.dart';
import 'package:myapp/services/ledger_service.dart';

class ViewLedgerScreen extends StatefulWidget {
  final int partyId;
  const ViewLedgerScreen({super.key, required this.partyId});

  @override
  State<ViewLedgerScreen> createState() => _ViewLedgerScreenState();
}

class _ViewLedgerScreenState extends State<ViewLedgerScreen> {
  bool loading = true;

  List<dynamic> ledgerList = [];
  double totalDebit = 0;
  double totalCredit = 0;
  double balance = 0;

  @override
  void initState() {
    super.initState();
    loadLedger();
  }

  Future<void> loadLedger() async {
    try {
      final data =
      await LedgerService.getLedgerByParty(widget.partyId);

      setState(() {
        ledgerList = data['ledger']['ledger'];
        totalDebit = double.tryParse("${data['ledger']['total_debit']}") ?? 0;
        totalCredit = double.tryParse("${data['ledger']['total_credit']}") ?? 0;
        balance = double.tryParse("${data['ledger']['balance']}") ?? 0;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ledger")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔹 Ledger List
          Expanded(
            child: ledgerList.isEmpty
                ? const Center(
              child: Text("No ledger entries"),
            )
                : ListView.builder(
              itemCount: ledgerList.length,
              itemBuilder: (context, index) {
                final l = ledgerList[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      "Voucher: ${l['voucher_no']}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text("Date: ${l['entry_date']}"),
                        Text("Type: ${l['transaction_type']}"),
                        Text("Narration: ${l['narration'] ?? '-'}"),
                        Text("Remark: ${l['remark'] ?? '-'}"),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text(
                          "Dr: ${l['debit']}",
                          style: const TextStyle(
                              color: Colors.green),
                        ),
                        Text(
                          "Cr: ${l['credit']}",
                          style: const TextStyle(
                              color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 🔹 TOTALS FOOTER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: const Border(
                top: BorderSide(color: Colors.black12),
              ),
            ),
            child: Column(
              children: [
                _totalRow("Total Debit", totalDebit,
                    Colors.green),
                _totalRow("Total Credit", totalCredit,
                    Colors.red),
                const Divider(),
                _totalRow(
                  "Balance",
                  balance,
                  balance >= 0
                      ? Colors.green
                      : Colors.red,
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
      String label, double value, Color color,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              fontWeight:
              bold ? FontWeight.bold : FontWeight.normal),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight:
            bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
