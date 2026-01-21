import 'package:flutter/material.dart';
import 'package:rbcledger/services/ledger_service.dart';

class EditLedgerEntryScreen extends StatefulWidget {
  final int ledgerId;
  final int partyId;
  final String partyName;
  final Map<String, dynamic> ledgerData;

  const EditLedgerEntryScreen({
    super.key,
    required this.ledgerId,
    required this.partyId,
    required this.partyName,
    required this.ledgerData,
  });

  @override
  State<EditLedgerEntryScreen> createState() => _EditLedgerEntryScreenState();
}

class _EditLedgerEntryScreenState extends State<EditLedgerEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final entryDateController = TextEditingController();
  final voucherController = TextEditingController();
  final amountController = TextEditingController();
  final narrationController = TextEditingController();
  final remarkController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> transactionTypes = [];
  int? transactionTypeId;

  String type = 'Dr';
  bool loading = true;
  bool saving = false;

  // ---------------- SAFE HELPERS ----------------
  double safeDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  int? safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  @override
  void initState() {
    super.initState();
    loadTransactionTypes();
  }

  // ---------------- LOAD TRANSACTION TYPES ----------------
  Future<void> loadTransactionTypes() async {
    try {
      final data = await LedgerService.getTransactionTypes();
      transactionTypes = data.map<Map<String, dynamic>>((e) {
        return {
          'id': safeInt(e['id']),
          'type': e['type'].toString(),
        };
      }).toList();

      loadExistingData();
      if (!transactionTypes.any((t) => t['id'] == transactionTypeId)) {
        transactionTypeId =
        transactionTypes.isNotEmpty ? transactionTypes.first['id'] : null;
      }

      setState(() => loading = false);
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ---------------- LOAD LEDGER DATA ----------------
  void loadExistingData() {
    final data = widget.ledgerData;
    String rawDate = data['entry_date'].toString();
    if (rawDate.contains('-') && rawDate.length == 8) {
      final p = rawDate.split('-');
      selectedDate =
          DateTime(int.parse('20${p[2]}'), int.parse(p[1]), int.parse(p[0]));
    } else {
      selectedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    }
    entryDateController.text = formatDate(selectedDate);
    final debit = safeDouble(data['debit']);
    final credit = safeDouble(data['credit']);
    type = debit > 0 ? 'Dr' : 'Cr';
    amountController.text =
        (debit > 0 ? debit : credit).toStringAsFixed(2);

    voucherController.text = data['voucher_no'] ?? '';
    narrationController.text = data['narration'] ?? '';
    remarkController.text = data['remark'] ?? '';
    transactionTypeId = safeInt(data['transaction_type_id']);
  }

  String formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        entryDateController.text = formatDate(picked);
      });
    }
  }

  // ---------------- UPDATE LEDGER ----------------
  Future<void> updateLedger() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      await LedgerService.updateLedger(
        ledgerId: widget.ledgerId,
        partyId: widget.partyId,
        transactionTypeId: transactionTypeId!,
        entryDate: formatDate(selectedDate),
        voucherNo:
        voucherController.text.trim().isEmpty ? null : voucherController.text,
        amount: double.parse(amountController.text),
        type: type,
        narration: narrationController.text,
        remark: remarkController.text,
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Update failed: $e")));
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    entryDateController.dispose();
    voucherController.dispose();
    amountController.dispose();
    narrationController.dispose();
    remarkController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit: ${widget.partyName}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: entryDateController,
                readOnly: true,
                onTap: pickDate,
                decoration: const InputDecoration(
                  labelText: "Entry Date",
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 12),

              // ✅ TRANSACTION TYPE (PERFECT FIX)
              DropdownButtonFormField<int>(
                key: ValueKey(transactionTypeId),
                initialValue: transactionTypeId,
                items: transactionTypes.map((t) {
                  return DropdownMenuItem<int>(
                    value: t['id'],
                    child: Text(t['type']),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    transactionTypeId = v;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Transaction Type",
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: voucherController,
                decoration:
                const InputDecoration(labelText: "Voucher No"),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                key: ValueKey(type),
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'Dr', child: Text("Debit")),
                  DropdownMenuItem(value: 'Cr', child: Text("Credit")),
                ],
                onChanged: (v) => setState(() => type = v!),
                decoration: const InputDecoration(labelText: "Type"),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: amountController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Amount"),
                validator: (v) =>
                v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: narrationController,
                decoration:
                const InputDecoration(labelText: "Narration"),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: remarkController,
                decoration:
                const InputDecoration(labelText: "Remark"),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : updateLedger,
                  child: saving
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text("Update Ledger"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
