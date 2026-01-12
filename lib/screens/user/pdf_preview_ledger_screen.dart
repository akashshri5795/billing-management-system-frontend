import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:rbcledger/services/ledger_pdf_service.dart';

class LedgerPdfPreviewScreen extends StatelessWidget {
  final String partyName;
  final String partyAddress;
  final List<dynamic> ledgerList;
  final double openingBalanceDebit;
  final double openingBalanceCredit;
  final double totalDebit;
  final double totalCredit;
  final double balance;

  const LedgerPdfPreviewScreen({
    super.key,
    required this.partyName,
    required this.partyAddress,
    required this.ledgerList,
    required this.openingBalanceDebit,
    required this.openingBalanceCredit,
    required this.totalDebit,
    required this.totalCredit,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ledger - $partyName', style: TextStyle(color: Colors.white),), backgroundColor: Colors.deepPurple.shade400,),
      body: PdfPreview(
        maxPageWidth: 700, // optional: set max width
        canChangePageFormat: true,
        canChangeOrientation: true,
        build: (format) async {
          return await LedgerPdfService.generateLedgerPdf(
            partyName: partyName,
            partyAddress: partyAddress,
            ledgerList: ledgerList,
            openingBalanceDebit: openingBalanceDebit,
            openingBalanceCredit: openingBalanceCredit,
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            balance: balance,
          );
        },
      ),
    );
  }
}
