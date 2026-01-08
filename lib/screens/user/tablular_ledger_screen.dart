import 'package:flutter/material.dart';
import 'package:rbcledger/services/ledger_service.dart';

class TabularLedgerScreen extends StatefulWidget {
  final int partyId;
  const TabularLedgerScreen({super.key, required this.partyId});

  @override
  State<TabularLedgerScreen> createState() => _TabularLedgerScreenState();
}

class _TabularLedgerScreenState extends State<TabularLedgerScreen> {
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
      appBar: AppBar(title: Text(partyName, style: TextStyle(color: Colors.white),), backgroundColor: Colors.teal,),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _openingBalanceHeader(),
          Expanded(
            child: ledgerList.isEmpty
                ? const Center(child: Text("No ledger entries"))
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columnSpacing: 25,
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade300),
                  columns: const [
                    DataColumn(label: Text("Date")),
                    DataColumn(label: Text("Voucher")),
                    DataColumn(label: Text("Type")),
                    DataColumn(label: Text("Debit")),
                    DataColumn(label: Text("Credit")),
                  ],
                  rows: ledgerList.map<DataRow>((l) {
                    return DataRow(
                      cells: [
                        DataCell(Text(l['entry_date'] ?? '-')),
                        DataCell(Text(l['voucher_no'] ?? '-')),
                        DataCell(Text(l['transaction_type'] ?? '-')),
                        DataCell(
                          Text(
                            (l['debit'] ?? 0).toString(),
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                        DataCell(
                          Text(
                            (l['credit'] ?? 0).toString(),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
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
