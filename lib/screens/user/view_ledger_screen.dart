import 'package:flutter/material.dart';
import 'package:rbcledger/screens/user/pdf_preview_ledger_screen.dart';
import 'package:rbcledger/screens/user/tablular_ledger_screen.dart';
import 'package:rbcledger/services/ledger_service.dart';

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
  double openingBalanceDebit = 0;
  double openingBalanceCredit = 0;
  double balance = 0;

  String partyName = 'Party';

  @override
  void initState() {
    super.initState();
    loadLedger();
  }

  Future<void> loadLedger() async {
    try {
      final List<dynamic> response =
      await LedgerService.getLedgerByParty(widget.partyId);

      if (response.isEmpty) {
        throw Exception('No ledger data found');
      }

      final data = response.first;

      double safeDouble(dynamic val) {
        if (val == null) return 0;
        if (val is double) return val;
        if (val is int) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0;
        return 0;
      }
      setState(() {
        ledgerList = data['ledger'] ?? [];
        partyName = data['party']?['name'] ?? 'Party';
        openingBalanceDebit = safeDouble(data['opening_balance_dr']);
        openingBalanceCredit = safeDouble(data['opening_balance_cr']);
        totalDebit = safeDouble(data['total_debit']);
        totalCredit = safeDouble(data['total_credit']);
        balance = safeDouble(data['balance']);
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(partyName, style: TextStyle(color: Colors.white),),
      actions: [
        IconButton(
          icon: const Icon(Icons.table_view, color: Colors.white,), // Replace with your desired icon
          tooltip: "Tabluar View",
          onPressed: () async {
            final added = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TabularLedgerScreen(
                  partyId: widget.partyId,
                ),
              ),
            );

            if (added == true) {
              loadLedger(); // refresh ledger
            }
          },
        ),

        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LedgerPdfPreviewScreen(
                  partyName: partyName,
                  ledgerList: ledgerList,
                  openingBalanceDebit: openingBalanceDebit,
                  openingBalanceCredit: openingBalanceCredit,
                  totalDebit: totalDebit,
                  totalCredit: totalCredit,
                  balance: balance,
                ),
              ),
            );
          },
          icon: const Icon(Icons.picture_as_pdf, color: Colors.teal,),
          label: const Text('Preview', style: TextStyle(color: Colors.teal),),
        ),

      ],
        backgroundColor: Colors.teal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔹 OPENING BALANCE HEADER
          _openingBalanceHeader(),

          // 🔹 LEDGER LIST
          Expanded(
            child: ledgerList.isEmpty
                ? const Center(child: Text("No ledger entries"))
                : ListView.builder(
              itemCount: ledgerList.length,
              itemBuilder: (context, index) {
                final l = ledgerList[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: voucher + info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Voucher number
                              Text(
                                "Voucher: ${l['voucher_no']}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              // Details
                              Text("Date: ${l['entry_date']}"),
                              Text("Type: ${l['transaction_type']}"),
                              Text(
                                "Narration: ${l['narration'] ?? '-'}",
                                style: const TextStyle(fontSize: 12, color: Colors.green),
                              ),
                              Text(
                                "Remark: ${l['remark'] ?? '-'}",
                                style: const TextStyle(fontSize: 12, color: Colors.purple),
                              ),
                            ],
                          ),
                        ),

                        // Right side: Edit / DrCr / Delete
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Dr: ${l['debit']}",
                                  style: const TextStyle(fontSize: 12, color: Colors.green),
                                ),
                                Text(
                                  "Cr: ${l['credit']}",
                                  style: const TextStyle(fontSize: 12, color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                    ),
                    ),
                );
              },
            ),
          ),

          // 🔹 TOTALS FOOTER
          _totalsFooter(),
        ],
      ),
    );
  }

  // ================== WIDGETS ==================

  Widget _openingBalanceHeader() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Opening Balance",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _balanceRow("Debit", openingBalanceDebit, Colors.green),
          const SizedBox(height: 6),
          _balanceRow("Credit", openingBalanceCredit, Colors.red),
        ],
      ),
    );
  }

  Widget _totalsFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: const Border(
          top: BorderSide(color: Colors.black12),
        ),
      ),
      child: Column(
        children: [
          _balanceRow("Total Debit", totalDebit, Colors.green),
          _balanceRow("Total Credit", totalCredit, Colors.red),
          const Divider(),
          _balanceRow(
            "Balance",
            balance,
            balance >= 0 ? Colors.green : Colors.red,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _balanceRow(String label, double value, Color color,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
