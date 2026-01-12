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

  static const String companyName = "ROHAN BOOK COMPANY PVT. LTD.";
  static const String companyAddress =
      "56/50, Site-4, Sahibabad Industrial Area, Ghaziabad-201010";
  static const String companyGSTIN =
      "CIN : U7900DL2012PTC234271; GSTIN : 09AAFCR8431A1ZJ";
  static final pw.TextStyle tableDataStyle = pw.TextStyle(fontSize: 9);
  static final pw.TextStyle tableHeaderStyle = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
  );

  // Generate PDF
  static Future<Uint8List> generateLedgerPdf({
    required String partyName,
    required String partyAddress,
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
        build: (context) {
          final ledgerRows = ledgerList.map<pw.TableRow>((l) {
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(l['entry_date'] ?? '', style: tableDataStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(
                    l['transaction_type'] ?? '',
                    style: tableDataStyle,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(l['voucher_no'] ?? '', style: tableDataStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(l['narration'] ?? '', style: tableDataStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      safeDouble(l['debit']).toStringAsFixed(2),
                      style: tableDataStyle.copyWith(color: PdfColors.green),
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      safeDouble(l['credit']).toStringAsFixed(2),
                      style: tableDataStyle.copyWith(color: PdfColors.red800),
                    ),
                  ),
                ),
              ],
            );
          }).toList();

          // TOTAL row
          final totalRow = pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              pw.Container(),
              pw.Container(),
              pw.Container(),
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    safeDouble(totalDebit).toStringAsFixed(2),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    safeDouble(totalCredit).toStringAsFixed(2),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          );

          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Center(
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(companyAddress, style: pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 2),
                    pw.Text(companyGSTIN, style: pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "LEDGER",
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '$partyName ($partyAddress)',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            // Opening balance
            pw.Container(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Opening Debit: ${safeDouble(openingBalanceDebit).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                  pw.Text(
                    'Opening Credit: ${safeDouble(openingBalanceCredit).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 8),

            // Ledger table
            pw.Table(
              border: pw.TableBorder.all(width: 0.1),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children:
                      [
                            'Date',
                            'Type',
                            'Voucher No',
                            'Narration',
                            'Debit',
                            'Credit',
                          ]
                          .map(
                            (e) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(e, style: tableHeaderStyle),
                            ),
                          )
                          .toList(),
                ),
                // Ledger rows
                ...ledgerRows,
                // TOTAL row
                totalRow,
              ],
            ),

            pw.SizedBox(height: 8),

            // Totals & balance
            pw.Container(
              color: PdfColors.grey200,
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Debit: ${safeDouble(totalDebit + openingBalanceDebit).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Total Credit: ${safeDouble(totalCredit + openingBalanceCredit).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red700,
                      fontSize: 10,
                    ),
                  ),
                  pw.Divider(),
                  pw.Text(
                    'Balance: ${safeDouble(balance).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: balance >= 0 ? PdfColors.green : PdfColors.red,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Preview / Share PDF
  static Future<void> previewLedgerPdf({
    required String partyName,
    required String partyAddress,
    required List<dynamic> ledgerList,
    required double openingBalanceDebit,
    required double openingBalanceCredit,
    required double totalDebit,
    required double totalCredit,
    required double balance,
  }) async {
    final pdfData = await generateLedgerPdf(
      partyName: partyName,
      partyAddress: partyAddress,
      ledgerList: ledgerList,
      openingBalanceDebit: openingBalanceDebit,
      openingBalanceCredit: openingBalanceCredit,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      balance: balance,
    );

    await Printing.sharePdf(
      bytes: pdfData,
      filename: '${partyName}_ledger_report.pdf',
    );
  }
}
