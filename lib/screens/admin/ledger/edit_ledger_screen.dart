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

  List<dynamic> transactionTypes = [];
  int? transactionTypeId;

  String type = 'Dr';
  bool loading = true;
  bool saving = false;

  double debit = 0;
  double credit = 0;

  double safeDouble(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    loadTransactionTypes();
  }

  void _loadExistingData() {
    final data = widget.ledgerData;

    debit = safeDouble(data['debit']);
    credit = safeDouble(data['credit']);

    selectedDate = DateTime.parse(data['entry_date']);
    entryDateController.text = _formatDate(selectedDate);

    voucherController.text = data['voucher_no'] ?? '';
    amountController.text =
        (debit > 0 ? debit : credit).toStringAsFixed(2);

    type = debit > 0 ? 'Dr' : 'Cr';

    narrationController.text = data['narration'] ?? '';
    remarkController.text = data['remark'] ?? '';

    transactionTypeId = data['transaction_type_id'];
  }

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

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
        entryDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> loadTransactionTypes() async {
    try {
      final data = await LedgerService.getTransactionTypes();
      setState(() {
        transactionTypes = data;
        transactionTypeId ??= data.first['id'];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading transaction types: $e")),
      );
    }
  }

  Future<void> updateLedger() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      await LedgerService.updateLedger(
        ledgerId: widget.ledgerId,
        partyId: widget.partyId,
        transactionTypeId: transactionTypeId!,
        entryDate: selectedDate.toIso8601String(),
        voucherNo: voucherController.text.trim(),
        amount: double.tryParse(amountController.text) ?? 0,
        type: type,
        narration: narrationController.text.trim(),
        remark: remarkController.text.trim(),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating ledger: $e")),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit: ${widget.partyName}", style: TextStyle(color: Colors.white),), backgroundColor: Colors.teal,),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Entry Date
              TextFormField(
                controller: entryDateController,
                readOnly: true,
                onTap: pickDate,
                decoration: const InputDecoration(
                  labelText: "Entry Date",
                  suffixIcon: Icon(Icons.calendar_today, color: Colors.teal,),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? "Select date" : null,
              ),
              const SizedBox(height: 12),

              // Transaction Type
              DropdownButtonFormField<int>(
                value: transactionTypeId,
                items: transactionTypes
                    .map(
                      (t) => DropdownMenuItem<int>(
                    value: t['id'],
                    child: Text(t['type']),
                  ),
                )
                    .toList(),
                onChanged: (v) =>
                    setState(() => transactionTypeId = v),
                decoration: const InputDecoration(
                  labelText: "Transaction Type",
                ),
                validator: (v) =>
                v == null ? "Select transaction type" : null,
              ),
              const SizedBox(height: 12),

              // Voucher No
              TextFormField(
                controller: voucherController,
                decoration:
                const InputDecoration(labelText: "Voucher No"),
                validator: (v) =>
                v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),

              // Dr / Cr
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(
                      value: 'Dr', child: Text("Debit")),
                  DropdownMenuItem(
                      value: 'Cr', child: Text("Credit")),
                ],
                onChanged: (v) => setState(() => type = v!),
                decoration:
                const InputDecoration(labelText: "Type"),
              ),
              const SizedBox(height: 12),

              // Amount
              TextFormField(
                controller: amountController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration:
                const InputDecoration(labelText: "Amount"),
                validator: (v) =>
                v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),

              // Narration
              TextFormField(
                controller: narrationController,
                decoration:
                const InputDecoration(labelText: "Narration"),
              ),
              const SizedBox(height: 12),

              // Remark
              TextFormField(
                controller: remarkController,
                decoration:
                const InputDecoration(labelText: "Remark"),
              ),
              const SizedBox(height: 20),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : updateLedger,
                  child: saving
                      ? const CircularProgressIndicator(
                      color: Colors.white)
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
