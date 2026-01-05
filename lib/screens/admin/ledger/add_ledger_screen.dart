import 'package:flutter/material.dart';
import 'package:myapp/services/ledger_service.dart';

class AddLedgerEntryScreen extends StatefulWidget {
  final int partyId;
  const AddLedgerEntryScreen({super.key, required this.partyId});

  @override
  State<AddLedgerEntryScreen> createState() => _AddLedgerEntryScreenState();
}

class _AddLedgerEntryScreenState extends State<AddLedgerEntryScreen> {
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

  @override
  void initState() {
    super.initState();
    entryDateController.text = _formatDate(selectedDate);
    loadTransactionTypes();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

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
        transactionTypeId = data.first['id'];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> saveLedger() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      await LedgerService.addLedger(
        partyId: widget.partyId,
        transactionTypeId: transactionTypeId!,
        entryDate: selectedDate.toIso8601String(),
        voucherNo: voucherController.text.trim(),
        amount: double.parse(amountController.text),
        type: type,
        narration: narrationController.text.trim(),
        remark: remarkController.text.trim(),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Ledger Entry")),
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
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (v) =>
                v!.isEmpty ? "Select date" : null,
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
              ),
              const SizedBox(height: 12),

              // Voucher No
              TextFormField(
                controller: voucherController,
                decoration:
                const InputDecoration(labelText: "Voucher No"),
                validator: (v) =>
                v!.isEmpty ? "Required" : null,
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
                onChanged: (v) =>
                    setState(() => type = v!),
                decoration:
                const InputDecoration(labelText: "Type"),
              ),
              const SizedBox(height: 12),

              // Amount
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration:
                const InputDecoration(labelText: "Amount"),
                validator: (v) =>
                v!.isEmpty ? "Required" : null,
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

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : saveLedger,
                  child: saving
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text("Save Ledger"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
