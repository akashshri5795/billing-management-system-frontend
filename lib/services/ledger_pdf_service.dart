import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class LedgerPdfService {
  // Safe double conversion
  static double safeDouble(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  static Future<Uint8List> generateLedgerPdf({
    required String partyName,
    required List<dynamic> ledgerList,
    required double openingBalanceDebit,
    required double openingBalanceCredit,
    required double totalDebit,
    required double totalCredit,
    required double balance,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Ledger Report - $partyName',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),

          // Opening balance
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Opening Debit: ${safeDouble(openingBalanceDebit).toStringAsFixed(2)}'),
              pw.Text('Opening Credit: ${safeDouble(openingBalanceCredit).toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 12),

          // Ledger table
          pw.Table.fromTextArray(
            headers: [
              'Date',
              'Voucher No',
              'Type',
              'Narration',
              'Remark',
              'Dr',
              'Cr',
            ],
            data: ledgerList.map((l) {
              return [
                l['entry_date'] ?? '',
                l['voucher_no'] ?? '',
                l['transaction_type'] ?? '',
                l['narration'] ?? '',
                l['remark'] ?? '',
                safeDouble(l['debit']).toStringAsFixed(2),
                safeDouble(l['credit']).toStringAsFixed(2),
              ];
            }).toList(),
            border: pw.TableBorder.all(width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
          pw.SizedBox(height: 12),

          // Totals and balance
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Debit: ${safeDouble(totalDebit).toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Total Credit: ${safeDouble(totalCredit).toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text('Balance: ${safeDouble(balance).toStringAsFixed(2)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

    return pdf.save();
  }

  // Preview / print PDF
  static Future<void> previewLedgerPdf({
    required String partyName,
    required List<dynamic> ledgerList,
    required double openingBalanceDebit,
    required double openingBalanceCredit,
    required double totalDebit,
    required double totalCredit,
    required double balance,
  }) async {
    final pdfData = await generateLedgerPdf(
      partyName: partyName,
      ledgerList: ledgerList,
      openingBalanceDebit: openingBalanceDebit,
      openingBalanceCredit: openingBalanceCredit,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      balance: balance,
    );

    // Use sharePdf instead of layoutPdf to avoid MissingPluginException
    await Printing.sharePdf(bytes: pdfData, filename: '${partyName}_ledger_report.pdf');
  }

}
