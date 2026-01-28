import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rbcledger/services/ledger_service.dart';
import 'package:rbcledger/utils/amount_formatter.dart';

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
      final response = await LedgerService.getLedgerByParty(widget.partyId);

      if (response.isEmpty) throw Exception('No ledger data found');

      final data = response.first;

      double safeDouble(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v.toDouble();
        if (v is double) return v;
        if (v is String) return double.tryParse(v) ?? 0;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(partyName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _openingBalanceHeader(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    Colors.grey.shade300,
                  ),
                  columnSpacing: 12,
                  columns: const [
                    DataColumn(
                      label: Text(
                        "Date",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Type",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Voucher No",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Narration",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Debit",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Credit",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  /// ✅ CORRECT ROWS
                  rows: [
                    ...ledgerList.map<DataRow>((l) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              l['entry_date'] ?? '-',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              l['transaction_type'] ?? '-',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120, // adjust as needed
                              child: Text(
                                l['voucher_no'] ?? '-',
                                style: const TextStyle(fontSize: 12),
                                softWrap: true,
                                maxLines: null,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 300, // narration ke liye zyada width
                              child: Text(
                                l['narration'] ?? '-',
                                style: const TextStyle(fontSize: 12),
                                softWrap: true,
                                maxLines: null,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ),
                          DataCell(
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                AmountFormatter.format(l['debit'] ?? 0),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                AmountFormatter.format(l['credit'] ?? 0),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    /// 🔹 TOTAL ROW
                    DataRow(
                      color: MaterialStateProperty.all(
                        Colors.grey.shade200,
                      ),
                      cells: [
                        const DataCell(
                          Text(
                            "TOTAL",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const DataCell(Text("")),
                        const DataCell(Text("")),
                        const DataCell(Text("")),
                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              AmountFormatter.format(totalDebit),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              AmountFormatter.format(totalCredit),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          _totalsFooter(),
        ],
      ),
    );
  }

  // ===================== UI HELPERS =====================

  Widget _openingBalanceHeader() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Opening Balance",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _balanceRow("Debit", openingBalanceDebit, Colors.green),
            _balanceRow("Credit", openingBalanceCredit, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _totalsFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade200,
      child: Column(
        children: [
          _balanceRow(
            "Total Debit",
            totalDebit + openingBalanceDebit,
            Colors.green,
          ),
          _balanceRow(
            "Total Credit",
            totalCredit + openingBalanceCredit,
            Colors.red,
          ),
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

  Widget _balanceRow(
      String label,
      double value,
      Color color, {
        bool bold = false,
      }) {
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
