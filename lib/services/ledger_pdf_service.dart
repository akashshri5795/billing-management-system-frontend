import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:rbcledger/utils/amount_formatter.dart';

class LedgerPdfService {
  // Safe double conversion

  static const String companyName = "ROHAN BOOK COMPANY PVT LTD";
  static const String companyAddress =
      "56/50, Site-4, Sahibabad Industrial Area, Ghaziabad-201010";
  static const String companyGSTIN =
      "CIN : U74900DL2012PTC234271; GSTIN : 09AAFCR8431A1ZJ";
  static const String companyPhone =
      "M.No.: 9811230507";
  static final pw.TextStyle tableDataStyle = pw.TextStyle(fontSize: 8);
  static final pw.TextStyle tableHeaderStyle = pw.TextStyle(
    fontSize: 9,
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
                  child: pw.Text(l['voucher_no'] ?? '', style: tableDataStyle, softWrap: true,),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(l['narration'] ?? '', style: tableDataStyle, softWrap: true,),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      AmountFormatter.format(l['debit']),
                      style: tableDataStyle,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      AmountFormatter.format(l['credit']),
                      style: tableDataStyle,
                    ),
                  ),
                ),
              ],
            );
          }).toList();

          // TOTAL row
          final totalRow = pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300,
              border: pw.Border(
                top: pw.BorderSide(width: 0.5),
                bottom: pw.BorderSide(width: 0.5),
              ),
            ),
            children: [
              pw.Container(),
              pw.Container(),
              pw.Container(),
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    AmountFormatter.format(totalDebit),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    AmountFormatter.format(totalCredit),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ],
          );

          return [
            // Header
            pw.Header(
              child: pw.Center(
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(companyAddress, style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text(companyGSTIN, style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text(companyPhone, style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "LEDGER",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '$partyName ($partyAddress)',
                      style: pw.TextStyle(
                        fontSize: 10,
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
                    'Opening Debit: ${ AmountFormatter.format(openingBalanceDebit)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    'Opening Credit: ${ AmountFormatter.format(openingBalanceCredit)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 8),

            // Ledger table
            pw.Table(
              columnWidths: {
                0: const pw.FixedColumnWidth(55),   // Date
                1: const pw.FixedColumnWidth(45),   // Type
                2: const pw.FixedColumnWidth(65),   // Voucher No (WRAP)
                3: const pw.FlexColumnWidth(3),     // Narration (AUTO WRAP)
                4: const pw.FixedColumnWidth(55),   // Debit
                5: const pw.FixedColumnWidth(55),   // Credit
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    border: pw.Border(
                      top: pw.BorderSide(width: 0.5),
                      bottom: pw.BorderSide(width: 0.5),
                    ),
                  ),
                  children: [
                    // Date
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Date', style: tableHeaderStyle),
                    ),

                    // Type
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Type', style: tableHeaderStyle),
                    ),

                    // Voucher No
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Voucher No', style: tableHeaderStyle),
                    ),

                    // Narration
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Narration', style: tableHeaderStyle),
                    ),

                    // Debit (RIGHT ALIGN)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Container(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text('Debit', style: tableHeaderStyle),
                      ),
                    ),

                    // Credit (RIGHT ALIGN)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Container(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text('Credit', style: tableHeaderStyle),
                      ),
                    ),
                  ],
                ),
            // Ledger rows
                ...ledgerRows,
                // TOTAL row
                totalRow,
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Debit: ${ AmountFormatter.format(totalDebit + openingBalanceDebit)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Total Credit: ${ AmountFormatter.format(totalCredit + openingBalanceCredit)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.Divider(),
                  pw.Text(
                    'Balance: ${ AmountFormatter.format(balance)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
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
